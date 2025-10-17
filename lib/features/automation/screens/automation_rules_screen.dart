import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/automation_rule.dart';
import '../providers/automation_provider.dart';
import 'add_edit_rule_screen.dart';
import 'rule_detail_screen.dart';

class AutomationRulesScreen extends StatefulWidget {
  const AutomationRulesScreen({Key? key}) : super(key: key);

  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutomationProvider>().loadRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_all') {
                _confirmDeleteAll(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Rules'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AutomationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadRules(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.rules.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildStatsBar(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadRules(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.rules.length,
                    itemBuilder: (context, index) {
                      final rule = provider.rules[index];
                      return _RuleCard(
                        rule: rule,
                        onTap: () => _navigateToDetail(context, rule),
                        onToggle: () => provider.toggleRule(rule.id),
                        onEdit: () => _navigateToEdit(context, rule),
                        onDelete: () => _confirmDelete(context, rule),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
    );
  }

  Widget _buildStatsBar(AutomationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.rule,
            label: 'Total',
            value: provider.totalRules.toString(),
            color: Colors.blue,
          ),
          _StatItem(
            icon: Icons.check_circle,
            label: 'Enabled',
            value: provider.enabledCount.toString(),
            color: Colors.green,
          ),
          _StatItem(
            icon: Icons.pause_circle,
            label: 'Disabled',
            value: (provider.totalRules - provider.enabledCount).toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Automation Rules',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first rule to automate your smart home',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Rule'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditRuleScreen()),
    );
  }

  void _navigateToEdit(BuildContext context, AutomationRule rule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditRuleScreen(rule: rule)),
    );
  }

  void _navigateToDetail(BuildContext context, AutomationRule rule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RuleDetailScreen(ruleId: rule.id)),
    );
  }

  void _confirmDelete(BuildContext context, AutomationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AutomationProvider>().deleteRule(rule.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final provider = context.read<AutomationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Rules'),
        content: Text(
          'Are you sure you want to delete all ${provider.totalRules} rules? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllRules();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Automation Works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Create Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Define conditions (e.g., temperature > 30°C)'),
              SizedBox(height: 12),
              Text(
                '2. Set Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Choose what devices to control'),
              SizedBox(height: 12),
              Text(
                '3. Enable Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Rules run automatically when conditions are met'),
              SizedBox(height: 12),
              Text(
                '💡 Tip: Rules have a 30-second cooldown to prevent rapid triggering.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final AutomationRule rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    rule.enabled ? Icons.check_circle : Icons.pause_circle,
                    color: rule.enabled ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (rule.lastTriggered != null)
                          Text(
                            'Last triggered ${timeago.format(rule.lastTriggered!)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  Switch(value: rule.enabled, onChanged: (_) => onToggle()),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    icon: Icons.filter_alt,
                    label:
                        '${rule.conditions.length} condition${rule.conditions.length != 1 ? 's' : ''}',
                    color: Colors.blue,
                  ),
                  _Chip(
                    icon: Icons.flash_on,
                    label:
                        '${rule.startActions.length} action${rule.startActions.length != 1 ? 's' : ''}',
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
