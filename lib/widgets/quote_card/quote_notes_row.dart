import 'package:flutter/material.dart';

class QuoteNotesRow extends StatelessWidget {
  final String note;
  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const QuoteNotesRow({
    Key? key,
    required this.note,
    required this.isEditing,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
              decoration: const InputDecoration(
                hintText: 'Editar nota...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 17),
            onPressed: () async => onSave(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 17),
            onPressed: onCancel,
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.white70, size: 17),
          onPressed: onEdit,
        ),
        Expanded(
          child: Text(
            note,
            style: TextStyle(
              color: note.isEmpty ? Colors.white38 : Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
