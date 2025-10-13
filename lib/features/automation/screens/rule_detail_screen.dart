import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/automation_rule.dart';
import '../providers/automation_provider.dart';
import 'add_edit_rule_screen.dart';

class RuleDetailScreen extends StatefulWidget {
  final String ruleId;

  const RuleDetailScreen({Key? key, required this.ruleId}) : super(key: key);

  @override
  State<RuleDetailScreen> createState() => _RuleDetailScreenState();
}

class _RuleDetailScreenState extends State<RuleDetailScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final provider = context.read<AutomationProvider>();
    final history = await provider.getRuleHistory(widget.ruleId);
    setState(() {
      _history = history;
      _loadingHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();
    final rule = provider.getRuleById(widget.ruleId);

    if (rule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rule Not Found')),
        body: const Center(child: Text('This rule no longer exists')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(rule.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(rule),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(rule, provider),
          const SizedBox(height: 16),
          _buildConditionsCard(rule),
          const SizedBox(height: 16),
          _buildActionsCard(rule),
          const SizedBox(height: 16),
          _buildHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AutomationRule rule, AutomationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: Theme.of(context).textTheme.titleLarge),
                Switch(
                  value: rule.enabled,
                  onChanged: (_) => provider.toggleRule(rule.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Created',
              value: timeago.format(rule.createdAt),
            ),
            if (rule.lastTriggered != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.history,
                label: 'Last Triggered',
                value: timeago.format(rule.lastTriggered!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsCard(AutomationRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conditions (ALL must be true)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...rule.conditions.map((condition) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatSensorName(condition.sensorType)} ${condition.operator} ${condition.value}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(AutomationRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...rule.actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${action.deviceId}: ${_formatAction(action.action)}${action.value != null ? " (${action.value})" : ""}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trigger History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHistory,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              const Text('No trigger history yet')
            else
              ..._history.take(5).map((record) {
                final triggeredAt = DateTime.parse(record['triggered_at']);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(timeago.format(triggeredAt)),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatSensorName(String type) {
    final names = {
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'light': 'Light',
      'rain': 'Rain',
      'soilMoisture': 'Soil Moisture',
      'gas': 'Gas',
      'dust': 'Dust',
      'motion': 'Motion',
    };
    return names[type] ?? type;
  }

  String _formatAction(String action) {
    final names = {
      'turn_on': 'Turn On',
      'turn_off': 'Turn Off',
      'toggle': 'Toggle',
      'set_value': 'Set Value',
    };
    return names[action] ?? action;
  }

  void _navigateToEdit(AutomationRule rule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditRuleScreen(rule: rule)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    );
  }
}
