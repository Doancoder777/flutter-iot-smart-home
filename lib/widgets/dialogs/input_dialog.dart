import 'package:flutter/material.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final Function(String) onConfirm;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const InputDialog({
    super.key,
    required this.title,
    this.hint,
    this.initialValue,
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    required this.onConfirm,
    this.validator,
    this.keyboardType,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              widget.onConfirm(_controller.text);
            }
          },
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
