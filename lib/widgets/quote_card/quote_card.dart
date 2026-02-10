import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
import '../../widgets/type_selector.dart';
import '../../widgets/cached_cover_image.dart';
import '../../screens/book_quotes_screen.dart';
import '../../screens/quote_fullscreen_screen.dart';
import 'quote_text_block.dart';
import 'quote_metadata_row.dart';
import 'quote_notes_row.dart';
import 'quote_action_overlay.dart';
import 'quote_actions_column.dart';


class QuoteCard extends StatefulWidget {
  final Map<String, dynamic> quote;
  final VoidCallback? onFavoriteChanged;

  const QuoteCard({
    required this.quote,
    this.onFavoriteChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final supabase = Supabase.instance.client;

  late TextEditingController _notesCtrl;

  // 🔹 NOVO: controller da quote (para editar o texto da quote)
  late TextEditingController _quoteCtrl;
  bool _editingQuote = false;

  bool _editing = false;
  bool _saving = false;
  late bool _isFavorite;

  bool _actionMode = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.quote['notes'] ?? '');

    // 🔹 NOVO
    _quoteCtrl = TextEditingController(text: widget.quote['text'] ?? '');

    final raw = widget.quote['is_favorite'];
    _isFavorite = raw == 1 || raw == true || raw == '1';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _quoteCtrl.dispose(); // 🔹 NOVO
    super.dispose();
  }

  Future<void> _updateNotes(String newText) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await supabase
          .from('quotes')
          .update({'notes': newText})
          .eq('id', widget.quote['id']);
    } finally {
      setState(() => _saving = false);
    }
  }

  // 🔹 NOVO: atualizar texto da quote
  Future<void> _updateQuoteText(String newText) async {
    if (_saving) return;

    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    setState(() => _saving = true);

    try {
      await supabase
          .from('quotes')
          .update({'text': trimmed})
          .eq('id', widget.quote['id']);

      widget.quote['text'] = trimmed;
      _quoteCtrl.text = trimmed;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _editingQuote = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final newValue = _isFavorite ? 0 : 1;

    setState(() {
      _isFavorite = !_isFavorite;
      widget.quote['is_favorite'] = newValue;
    });

    await supabase
        .from('quotes')
        .update({'is_favorite': newValue})
        .eq('id', widget.quote['id']);

    widget.onFavoriteChanged?.call();
  }

  Future<void> _copyQuote(
    Map<String, dynamic> q,
    Map<String, dynamic> book,
  ) async {
    final text = (q['text'] ?? '').toString().trim();
    final author = (book['author'] ?? '').toString().trim();
    final title = (book['title'] ?? '').toString().trim();

    final content = '$text\n\n$author - $title';

    await Clipboard.setData(ClipboardData(text: content));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote copiada'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  /// 🔴 OCULTAR / RESTAURAR (usa is_active)
  Future<void> _confirmAndDeactivateQuote() async {
    final int isActive =
        (widget.quote['is_active'] == 1 || widget.quote['is_active'] == true)
            ? 1
            : 0;

    if (isActive == 1) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Ocultar quote',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Esta quote será ocultada e não aparecerá mais nas listas.\n\nDeseja continuar?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Ocultar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await supabase
          .from('quotes')
          .update({'is_active': 0})
          .eq('id', widget.quote['id']);

      setState(() => widget.quote['is_active'] = 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote ocultada'),
            duration: Duration(milliseconds: 900),
          ),
        );
      }
      return;
    }

    await supabase
        .from('quotes')
        .update({'is_active': 1})
        .eq('id', widget.quote['id']);

    setState(() => widget.quote['is_active'] = 1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote restaurada'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  /// ❌ EXCLUIR DEFINITIVAMENTE (DELETE)
  Future<void> _confirmAndDeleteQuote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Excluir quote',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta quote será excluída permanentemente.\n\nEssa ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await supabase
        .from('quotes')
        .delete()
        .eq('id', widget.quote['id']);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote excluída'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  int _safeType(dynamic rawType) {
    if (rawType == null) return 0;
    if (rawType is int) return rawType;
    if (rawType is num) return rawType.toInt();
    return int.tryParse(rawType.toString()) ?? 0;
  }

  void _openBook(Map<String, dynamic> book, Map<String, dynamic> q) {
    final bookId = q['book_id'];
    if (bookId == null) return;

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
        (q['books'] is Map<String, dynamic>) ? q['books'] : {};

    final cover = (book['cover'] ?? '').toString();
    final color = colorByType(_safeType(q['type']));
    final note = _notesCtrl.text.trim();

//     final pageText = (q['page'] == null ||
//             q['page'].toString().trim().isEmpty ||
//             q['page'].toString() == 'null')
//         ? '--'
//         : q['page'].toString();

    return Card(
      color: color,
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
              builder: (_) => QuoteFullscreenScreen(quote: q),
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
                        GestureDetector(
                          onTap: () => _openBook(book, q),
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
                            QuoteTextBlock(
                              text: q['text'] ?? '',
                              controller: _quoteCtrl,
                              isEditing: _editingQuote,
                              onEdit: () {
                                _quoteCtrl.text = (q['text'] ?? '').toString();
                                setState(() => _editingQuote = true);
                              },
                              onCancel: () {
                                _quoteCtrl.text = (q['text'] ?? '').toString();
                                setState(() => _editingQuote = false);
                              },
                              onSave: () async {
                                await _updateQuoteText(_quoteCtrl.text);
                              },
                            ),

                            QuoteMetadataRow(
                              book: book,
                            ),

                          ],
                        ),
                      ),

                      // ⬅️ AQUI entra a coluna fixa
                      QuoteActionsColumn(
                        isActive: q['is_active'] == 1,
                        isFavorite: _isFavorite,
                        onEditQuote: () {
                          _quoteCtrl.text = (q['text'] ?? '').toString();
                          setState(() => _editingQuote = true);
                        },
                        onToggleFavorite: _toggleFavorite,
                        onOpenTypeSelector: () {
                          TypeSelector.show(
                            context,
                            currentType: _safeType(q['type']),
                            quoteId: q['id'],
                            isActive: q['is_active'] == 1,
                            onTypeChanged: (newType) {
                              if (newType == -1) {
                                _confirmAndDeactivateQuote();
                                return;
                              }
                              setState(() => widget.quote['type'] = newType);
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: QuoteNotesRow(
                             note: note,
                             isEditing: _editing,
                             controller: _notesCtrl,
                             onEdit: () => setState(() => _editing = true),
                             onCancel: () {
                               _notesCtrl.text = note;
                               setState(() => _editing = false);
                             },
                             onSave: () async {
                               await _updateNotes(_notesCtrl.text.trim());
                               setState(() => _editing = false);
                             },
                           ),

                  ),
                ],
              ),
            ),

            if (_actionMode)
              QuoteActionOverlay(
                onCopy: () async {
                  await _copyQuote(q, book);
                  setState(() => _actionMode = false);
                },
                onDelete: () async {
                  setState(() => _actionMode = false);
                  await _confirmAndDeleteQuote();
                },
                onClose: () => setState(() => _actionMode = false),
              ),
          ],
        ),
      ),
    );
  }
}
