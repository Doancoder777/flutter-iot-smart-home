import 'package:flutter/material.dart';
import 'widgets/condition_builder.dart';
import 'widgets/action_builder.dart';

/// Màn hình chỉnh sửa quy tắc tự động
class EditRuleScreen extends StatefulWidget {
  final String ruleId;
  final String ruleName;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> action;

  const EditRuleScreen({
    Key? key,
    required this.ruleId,
    required this.ruleName,
    required this.condition,
    required this.action,
  }) : super(key: key);

  @override
  State<EditRuleScreen> createState() => _EditRuleScreenState();
}

class _EditRuleScreenState extends State<EditRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Map<String, dynamic> _condition = {};
  Map<String, dynamic> _action = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ruleName);
    _condition = widget.condition;
    _action = widget.action;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa quy tắc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tên quy tắc
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên quy tắc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên quy tắc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Điều kiện
            ConditionBuilder(
              initialCondition: _condition,
              onConditionChanged: (condition) {
                setState(() {
                  _condition = condition;
                });
              },
            ),
            const SizedBox(height: 16),

            // Hành động
            ActionBuilder(
              initialAction: _action,
              onActionChanged: (action) {
                setState(() {
                  _action = action;
                });
              },
            ),
            const SizedBox(height: 24),

            // Nút cập nhật
            ElevatedButton(
              onPressed: _handleUpdateRule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cập nhật quy tắc',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdateRule() {
    if (_formKey.currentState!.validate()) {
      // Cập nhật quy tắc
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật "${_nameController.text}"'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa quy tắc'),
        content: Text('Bạn có chắc muốn xóa "${widget.ruleName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay lại màn hình trước
              // Xóa quy tắc
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
