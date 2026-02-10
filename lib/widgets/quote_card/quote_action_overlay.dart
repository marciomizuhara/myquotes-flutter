import 'package:flutter/material.dart';

class QuoteActionOverlay extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const QuoteActionOverlay({
    Key? key,
    required this.onCopy,
    required this.onDelete,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_all,
                      size: 18, color: Colors.white70),
                  onPressed: onCopy,
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: Colors.white70),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
