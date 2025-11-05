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
  bool isEditing = false;
  late TextEditingController ratingCtrl;

  @override
  void initState() {
    super.initState();
    ratingCtrl = TextEditingController(
      text: (widget.character['rating'] ?? 0.0).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    ratingCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateRating() async {
    final newRating = double.tryParse(ratingCtrl.text) ?? 0.0;
    await CharactersHelper.supabase
        .from('characters')
        .update({'rating': newRating})
        .eq('id', widget.character['id']);
    setState(() {
      widget.character['rating'] = newRating;
      isEditing = false;
    });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showBook && cover.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cover,
                      height: 65,
                      width: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 65,
                        width: 45,
                        color: Colors.black26,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white38, size: 20),
                      ),
                    ),
                  ),
                if (widget.showBook) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.showBook && title.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 🔹 Rating editável inline
                isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 46,
                            child: TextField(
                              controller: ratingCtrl,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.greenAccent),
                            onPressed: _updateRating,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () => setState(() => isEditing = false),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () => setState(() => isEditing = true),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 10),
            if (desc.isNotEmpty)
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tags,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
