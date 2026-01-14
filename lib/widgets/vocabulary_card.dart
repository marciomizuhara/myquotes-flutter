import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/cached_cover_image.dart';
import '../screens/translation_screen.dart';

class VocabularyCard extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const VocabularyCard({
    required this.vocab,
    Key? key,
  }) : super(key: key);

  @override
  State<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<VocabularyCard> {
  final supabase = Supabase.instance.client;

  late TextEditingController _notesCtrl;
  bool _editing = false;
  bool _saving = false;
  late bool _isFavorite;
  bool _actionMode = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.vocab['notes'] ?? '');

    final raw = widget.vocab['is_favorite'];
    _isFavorite = raw == 1 || raw == true || raw == '1';
  }

  Future<void> _updateNotes(String newText) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await supabase
          .from('vocabulary')
          .update({'notes': newText})
          .eq('id', widget.vocab['id']);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final newValue = _isFavorite ? 0 : 1;

    setState(() {
      _isFavorite = !_isFavorite;
      widget.vocab['is_favorite'] = newValue;
    });

    await supabase
        .from('vocabulary')
        .update({'is_favorite': newValue})
        .eq('id', widget.vocab['id']);
  }

  Future<void> _copyVocabulary(
    Map<String, dynamic> v,
    Map<String, dynamic> book,
  ) async {
    final word = (v['word'] ?? '').toString().trim();
    final text = (v['text'] ?? '').toString().trim();
    final author = (book['author'] ?? '').toString().trim();
    final title = (book['title'] ?? '').toString().trim();

    final content = word.isNotEmpty
        ? '$word\n\n$text\n\n$author - $title'
        : '$text\n\n$author - $title';

    await Clipboard.setData(ClipboardData(text: content));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vocabulary copied'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vocab;
    final Map<String, dynamic> book =
        (v['books'] is Map<String, dynamic>) ? v['books'] : {};

    final cover = (book['cover'] ?? '').toString();
    final note = _notesCtrl.text.trim();

    final pageText = (v['page'] == null ||
            v['page'].toString().trim().isEmpty ||
            v['page'].toString() == 'null')
        ? '--'
        : v['page'].toString();

    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => setState(() => _actionMode = true),
        onTap: () {
          if (_actionMode) setState(() => _actionMode = false);
        },
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TranslationScreen(vocab: widget.vocab),
            ),
          );
        },

        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cover.isNotEmpty)
                        CachedCoverImage(
                          url: cover,
                          width: 48,
                          height: 70,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      if (cover.isNotEmpty) const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((v['word'] ?? '').toString().isNotEmpty)
                              Text(
                                v['word'],
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            Text(
                              v['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.3,
                                fontSize: 13.5,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['title'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        book['author'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 8.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'p. $pageText',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _editing ? _buildEditRow(note) : _buildNormalRow(note),
                  ),
                ],
              ),
            ),
            if (_actionMode)
              Positioned.fill(
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
                            onPressed: () async {
                              await _copyVocabulary(v, book);
                              setState(() => _actionMode = false);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.white70),
                            onPressed: () =>
                                setState(() => _actionMode = false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditRow(String note) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _notesCtrl,
            maxLines: null,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
            decoration: const InputDecoration(
              hintText: 'Edit meaning...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green, size: 17),
          onPressed: () async {
            await _updateNotes(_notesCtrl.text.trim());
            setState(() => _editing = false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent, size: 17),
          onPressed: () {
            _notesCtrl.text = note;
            setState(() => _editing = false);
          },
        ),
      ],
    );
  }

  Widget _buildNormalRow(String note) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.white70, size: 17),
          onPressed: () => setState(() => _editing = true),
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
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.redAccent : Colors.white38,
            size: 17,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }
}
