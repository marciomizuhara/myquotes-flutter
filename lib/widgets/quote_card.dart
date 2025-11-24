import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../widgets/type_selector.dart';
import '../widgets/cached_cover_image.dart';
import '../screens/book_quotes_screen.dart'; // 👈 IMPORT NECESSÁRIO

class QuoteCard extends StatefulWidget {
  final Map<String, dynamic> quote;
  final VoidCallback? onFavoriteChanged;

  const QuoteCard({required this.quote, this.onFavoriteChanged, Key? key})
      : super(key: key);

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final supabase = Supabase.instance.client;
  late TextEditingController _notesCtrl;
  bool _editing = false;
  bool _saving = false;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.quote['notes'] ?? '');

    final raw = widget.quote['is_favorite'];
    _isFavorite = raw == 1 || raw == true || raw == '1';

    debugPrint(
        '❤️ initState → id=${widget.quote['id']} is_favorite=$raw (_isFavorite=$_isFavorite)');
  }

  Future<void> _updateNotes(String newText) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await supabase
          .from('quotes')
          .update({'notes': newText})
          .eq('id', widget.quote['id']);
    } catch (e) {
      debugPrint('Erro ao atualizar nota: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newValue = _isFavorite ? 0 : 1;

      setState(() {
        _isFavorite = !_isFavorite;
        widget.quote['is_favorite'] = newValue;
      });

      await supabase
          .from('quotes')
          .update({'is_favorite': newValue})
          .eq('id', widget.quote['id'])
          .select('is_favorite')
          .maybeSingle();

      widget.onFavoriteChanged?.call();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar favorito: $e');
    }
  }

  int _safeType(dynamic rawType) {
    if (rawType == null) return 0;
    if (rawType is int) return rawType;
    if (rawType is num) return rawType.toInt();
    return int.tryParse(rawType.toString()) ?? 0;
  }

  void _copyQuote(Map<String, dynamic> q) {
    final text = q['text'] ?? '';
    final author = q['books']?['author'] ?? 'Autor desconhecido';
    final title = q['books']?['title'] ?? 'Livro não informado';
    final formatted = '$text\n\n$author - $title';

    Clipboard.setData(ClipboardData(text: formatted));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Citação copiada!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBook(Map<String, dynamic> book, Map<String, dynamic> q) {
    final bookId = q['book_id'];

    if (bookId == null) {
      debugPrint('⚠️ QuoteCard: bookId ausente, não navegando.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookQuotesScreen(
          bookId: bookId,
          bookTitle: book['title'] ?? '',
          bookAuthor: book['author'] ?? '',
          bookCover: book['cover'],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final q = widget.quote;

    final Map<String, dynamic> book =
        (q['books'] is Map<String, dynamic>) ? q['books'] as Map<String, dynamic> : {};
    final String cover = (book['cover'] ?? '').toString();

    final color = colorByType(_safeType(q['type']));
    final note = _notesCtrl.text.trim();

    final String pageText = (q['page'] == null ||
            q['page'].toString().trim().isEmpty ||
            q['page'].toString() == 'null')
        ? '--'
        : q['page'].toString();

    return GestureDetector(
      onDoubleTap: () => _copyQuote(q),
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cover.isNotEmpty)
                    GestureDetector(
                      onTap: () => _openBook(book, q), // 👈 CAPA CLICÁVEL
                      child: CachedCoverImage(
                        url: cover,
                        width: 48,
                        height: 70,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                  if (cover.isNotEmpty) const SizedBox(width: 6),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['text'] ?? '',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['title'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    book['author'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 8.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 1),
                              child: GestureDetector(
                                onTap: () => TypeSelector.show(
                                  context,
                                  currentType: _safeType(q['type']),
                                  quoteId: q['id'],
                                  onTypeChanged: (newType) {
                                    setState(() => widget.quote['type'] = newType);
                                  },
                                ),
                                child: Text(
                                  'p. $pageText',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildEditRow(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: _notesCtrl,
            maxLines: null,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 11,
              height: 1.1,
            ),
            decoration: const InputDecoration(
              hintText: 'Editar nota...',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.check, color: Colors.green, size: 17),
          onPressed: () async {
            final newText = _notesCtrl.text.trim();
            await _updateNotes(newText);
            setState(() => _editing = false);
          },
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, color: Colors.redAccent, size: 17),
          onPressed: () {
            setState(() {
              _notesCtrl.text = note;
              _editing = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNormalRow(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_note, color: Colors.white70, size: 17),
          onPressed: () => setState(() => _editing = true),
        ),
        Expanded(
          flex: 5,
          child: Text(
            note.isEmpty ? '' : note,
            style: TextStyle(
              color: note.isEmpty ? Colors.white38 : Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white38,
              size: 17,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
    );
  }
}
