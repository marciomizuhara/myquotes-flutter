import 'package:flutter/material.dart';

class QuoteTextBlock extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const QuoteTextBlock({
    Key? key,
    required this.text,
    required this.controller,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                height: 1.3,
                fontSize: 13.5,
                letterSpacing: 0.05,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(top: 2), // 🔑
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 2), // 🔑 ajuste fino
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              icon: const Icon(Icons.check,
                  color: Colors.green, size: 17),
              onPressed: () async => onSave(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 2), // 🔑
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              icon: const Icon(Icons.close,
                  color: Colors.redAccent, size: 17),
              onPressed: onCancel,
            ),
          ),
        ],
      );
    }


    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              height: 1.3,
              fontSize: 13.5,
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }
}
