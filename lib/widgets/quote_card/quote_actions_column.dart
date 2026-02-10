import 'package:flutter/material.dart';

class QuoteActionsColumn extends StatelessWidget {
  final bool isActive;
  final bool isFavorite;

  final VoidCallback onEditQuote;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenTypeSelector;

  const QuoteActionsColumn({
    Key? key,
    required this.isActive,
    required this.isFavorite,
    required this.onEditQuote,
    required this.onToggleFavorite,
    required this.onOpenTypeSelector,
  }) : super(key: key);

  Widget _icon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28, // ainda mais compacto
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✏️ editar quote
          _icon(
            icon: Icons.edit_note,
            onTap: onEditQuote,
          ),

          const SizedBox(height: 3),

          // 🔘 type / active
          InkWell(
            onTap: onOpenTypeSelector,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white38
                        : Colors.redAccent,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          // ❤️ favorite
          _icon(
            icon: isFavorite
                ? Icons.favorite
                : Icons.favorite_border,
            color: isFavorite
                ? Colors.redAccent
                : Colors.white38,
            onTap: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}
