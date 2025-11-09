import 'package:flutter/material.dart';
import '../utils/characters_helper.dart';

class CharacterCard extends StatefulWidget {
  final Map<String, dynamic> character;
  final bool showBook; // se deve exibir capa e título do livro

  const CharacterCard({
    required this.character,
    this.showBook = true,
    Key? key,
  }) : super(key: key);

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  Future<void> _updateRating(double newValue) async {
    await CharactersHelper.supabase
        .from('characters')
        .update({'rating': newValue})
        .eq('id', widget.character['id']);
  }

  void _increaseRating() async {
    final current = (widget.character['rating'] ?? 0.0).toDouble();
    final newRating = (current + 0.1).clamp(0.0, 10.0);
    setState(() => widget.character['rating'] = newRating);
    await _updateRating(newRating);
  }

  void _decreaseRating() async {
    final current = (widget.character['rating'] ?? 0.0).toDouble();
    final newRating = (current - 0.1).clamp(0.0, 10.0);
    setState(() => widget.character['rating'] = newRating);
    await _updateRating(newRating);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final name = (c['name'] ?? '').toString();
    final desc = (c['description'] ?? '').toString();
    final tags = (c['tags'] ?? '').toString();
    final rating = (c['rating'] ?? 0.0).toDouble();
    final book = c['books'] ?? {};
    final title = (book['title'] ?? '').toString();
    final cover = (book['cover'] ?? '').toString();

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8), // antes 12 → mais compacto
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showBook && cover.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      cover,
                      height: 55,
                      width: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 55,
                        width: 38,
                        color: Colors.black26,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white38, size: 18),
                      ),
                    ),
                  ),
                if (widget.showBook) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.showBook && title.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 🔹 Novo controle de rating com setas ↑ ↓
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _increaseRating,
                      child: const Icon(
                        Icons.arrow_drop_up,
                        color: Color(0xFF444444), // cinza suave sobre fundo #1E1E1E
                        size: 22, // levemente menor (antes 26)
                      ),
                    ),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: _decreaseRating,
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF444444),
                        size: 22,
                      ),
                    ),
                  ],
                )

              ],
            ),
            const SizedBox(height: 6),
            if (desc.isNotEmpty)
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tags,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
