import 'package:flutter/material.dart';
import 'single_action_builder.dart';

/// Widget quản lý danh sách actions (nhiều thiết bị)
class ActionsBuilder extends StatefulWidget {
  final List<Map<String, dynamic>>? initialActions;
  final ValueChanged<List<Map<String, dynamic>>> onActionsChanged;

  const ActionsBuilder({
    Key? key,
    this.initialActions,
    required this.onActionsChanged,
  }) : super(key: key);

  @override
  State<ActionsBuilder> createState() => _ActionsBuilderState();
}

class _ActionsBuilderState extends State<ActionsBuilder> {
  final List<Map<String, dynamic>> _actions = [];

  @override
  void initState() {
    super.initState();

    // Load initial actions nếu có
    if (widget.initialActions != null && widget.initialActions!.isNotEmpty) {
      _actions.addAll(widget.initialActions!);
    } else {
      // Mặc định có ít nhất 1 action
      _actions.add({});
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _notifyChange() {
    // Filter out empty actions
    final validActions = _actions
        .where((a) => a.isNotEmpty && a['device'] != null)
        .toList();
    widget.onActionsChanged(validActions);
  }

  void _addAction() {
    setState(() {
      _actions.add({});
    });
  }

  void _removeAction(int index) {
    setState(() {
      if (_actions.length > 1) {
        _actions.removeAt(index);
        _notifyChange();
      }
    });
  }

  void _updateAction(int index, Map<String, dynamic> actionData) {
    setState(() {
      _actions[index] = actionData;
      _notifyChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hành động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_actions.length} thiết bị',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách actions
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          itemBuilder: (context, index) {
            return SingleActionBuilder(
              key: ValueKey('action_$index'),
              initialAction: _actions[index].isNotEmpty
                  ? _actions[index]
                  : null,
              onActionChanged: (actionData) => _updateAction(index, actionData),
              onRemove: () => _removeAction(index),
              showRemoveButton: _actions.length > 1,
            );
          },
        ),

        // Nút thêm thiết bị
        OutlinedButton.icon(
          onPressed: _addAction,
          icon: const Icon(Icons.add),
          label: const Text('Thêm thiết bị'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mẹo: Bạn có thể thêm nhiều thiết bị cùng hoạt động với một điều kiện',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
