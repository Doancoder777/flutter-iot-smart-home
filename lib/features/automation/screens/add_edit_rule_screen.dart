import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';
import '../../../models/automation_rule.dart';
import '../providers/automation_provider.dart';

class AddEditRuleScreen extends StatefulWidget {
  final AutomationRule? rule;

  const AddEditRuleScreen({Key? key, this.rule}) : super(key: key);

  @override
  State<AddEditRuleScreen> createState() => _AddEditRuleScreenState();
}

class _AddEditRuleScreenState extends State<AddEditRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  List<Condition> _conditions = [];
  List<Action> _actions = [];
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');

    if (widget.rule != null) {
      _conditions = List.from(widget.rule!.conditions);
      _actions = List.from(widget.rule!.actions);
      _enabled = widget.rule!.enabled;
    } else {
      // Default: add one empty condition and action
      _conditions.add(
        Condition(sensorType: 'temperature', operator: '>', value: 25.0),
      );
      _actions.add(Action(deviceId: 'relay1', action: 'turn_on'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Rule' : 'Create Rule'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRule),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rule name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name',
                hintText: 'e.g., Turn on fan when hot',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a rule name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Enabled switch
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: const Text('Rule will run automatically when enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),

            const Divider(height: 32),

            // Conditions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conditions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _addCondition,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'All conditions must be true for the rule to trigger',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            ..._conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final condition = entry.value;
              return _buildConditionCard(context, condition, index);
            }).toList(),

            const Divider(height: 32),

            // Actions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Actions', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Actions will be executed when conditions are met',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            ..._actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              return _buildActionCard(context, action, index);
            }).toList(),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveRule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(isEdit ? 'Update Rule' : 'Create Rule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
    BuildContext context,
    Condition condition,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Condition ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeCondition(index),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sensor type dropdown
            DropdownButtonFormField<String>(
              value: condition.sensorType,
              decoration: const InputDecoration(
                labelText: 'Sensor',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'temperature',
                  child: Text('Temperature'),
                ),
                DropdownMenuItem(value: 'humidity', child: Text('Humidity')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'rain', child: Text('Rain')),
                DropdownMenuItem(
                  value: 'soilMoisture',
                  child: Text('Soil Moisture'),
                ),
                DropdownMenuItem(value: 'gas', child: Text('Gas')),
                DropdownMenuItem(value: 'dust', child: Text('Dust')),
                DropdownMenuItem(value: 'motion', child: Text('Motion')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _conditions[index] = Condition(
                      sensorType: value,
                      operator: condition.operator,
                      value: condition.value,
                    );
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Operator dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: condition.operator,
                    decoration: const InputDecoration(
                      labelText: 'Operator',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '>', child: Text('>')),
                      DropdownMenuItem(value: '<', child: Text('<')),
                      DropdownMenuItem(value: '>=', child: Text('>=')),
                      DropdownMenuItem(value: '<=', child: Text('<=')),
                      DropdownMenuItem(value: '==', child: Text('==')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _conditions[index] = Condition(
                            sensorType: condition.sensorType,
                            operator: value,
                            value: condition.value,
                          );
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Value input
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: condition.value.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final numValue = double.tryParse(value);
                      if (numValue != null) {
                        _conditions[index] = Condition(
                          sensorType: condition.sensorType,
                          operator: condition.operator,
                          value: numValue,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, Action action, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Action ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeAction(index),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Device ID input
            TextFormField(
              initialValue: action.deviceId,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                hintText: 'e.g., relay1, servo1',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _actions[index] = Action(
                  deviceId: value,
                  action: action.action,
                  value: action.value,
                );
              },
            ),

            const SizedBox(height: 12),

            // Action type dropdown
            DropdownButtonFormField<String>(
              value: action.action,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'turn_on', child: Text('Turn On')),
                DropdownMenuItem(value: 'turn_off', child: Text('Turn Off')),
                DropdownMenuItem(value: 'toggle', child: Text('Toggle')),
                DropdownMenuItem(value: 'set_value', child: Text('Set Value')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _actions[index] = Action(
                      deviceId: action.deviceId,
                      action: value,
                      value: action.value,
                    );
                  });
                }
              },
            ),

            // Optional value field for set_value action
            if (action.action == 'set_value') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: action.value?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Value (e.g., servo angle 0-180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = int.tryParse(value);
                  _actions[index] = Action(
                    deviceId: action.deviceId,
                    action: action.action,
                    value: numValue,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addCondition() {
    setState(() {
      _conditions.add(
        Condition(sensorType: 'temperature', operator: '>', value: 25.0),
      );
    });
  }

  void _removeCondition(int index) {
    if (_conditions.length > 1) {
      setState(() {
        _conditions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one condition is required')),
      );
    }
  }

  void _addAction() {
    setState(() {
      _actions.add(Action(deviceId: 'relay1', action: 'turn_on'));
    });
  }

  void _removeAction(int index) {
    if (_actions.length > 1) {
      setState(() {
        _actions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one action is required')),
      );
    }
  }

  void _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_conditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one condition')),
      );
      return;
    }

    if (_actions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one action')));
      return;
    }

    final rule = AutomationRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      enabled: _enabled,
      conditions: _conditions,
      actions: _actions,
      createdAt: widget.rule?.createdAt ?? DateTime.now(),
      lastTriggered: widget.rule?.lastTriggered,
    );

    final provider = context.read<AutomationProvider>();
    bool success;

    if (widget.rule != null) {
      success = await provider.updateRule(rule);
    } else {
      success = await provider.addRule(rule);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.rule != null ? 'Rule updated' : 'Rule created'),
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }
}
