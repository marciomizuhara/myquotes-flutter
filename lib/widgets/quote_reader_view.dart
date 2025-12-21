import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';
import '../widgets/type_selector.dart';

class QuoteReaderView extends StatefulWidget {
  final Map<String, dynamic> quote;
  final VoidCallback onDoubleTap;

  const QuoteReaderView({
    Key? key,
    required this.quote,
    required this.onDoubleTap,
  }) : super(key: key);

  @override
  State<QuoteReaderView> createState() => _QuoteReaderViewState();
}

class _QuoteReaderViewState extends State<QuoteReaderView>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _notesCtrl = TextEditingController();
  bool _editingNote = false;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.quote['notes'] ?? '';

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward(from: 0);
  }

  Future<void> _updateQuoteType(int newType) async {
    await supabase
        .from('quotes')
        .update({'type': newType})
        .eq('id', widget.quote['id']);

    setState(() => widget.quote['type'] = newType);
  }

  Future<void> _updateNotes(String newText) async {
    if (_savingNote) return;
    setState(() => _savingNote = true);

    await supabase
        .from('quotes')
        .update({'notes': newText})
        .eq('id', widget.quote['id']);

    setState(() {
      widget.quote['notes'] = newText;
      _savingNote = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final book = q['books'] ?? {};
    final bgColor = colorByType(q['type']);
    final cover = (book['cover'] ?? '').toString();
    final title = (book['title'] ?? '').toString();
    final author = (book['author'] ?? '').toString();
    final note = _notesCtrl.text.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColor.withOpacity(0.85),
              Colors.black.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (cover.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                cover,
                                width: 160,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 30),
                          Text(
                            q['text'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            author,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 📝 notas
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _editingNote
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _notesCtrl,
                                  autofocus: true,
                                  maxLines: null,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () async {
                                  await _updateNotes(
                                      _notesCtrl.text.trim());
                                  setState(() => _editingNote = false);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  _notesCtrl.text = note;
                                  setState(() => _editingNote = false);
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note,
                                    color: Colors.white70),
                                onPressed: () =>
                                    setState(() => _editingNote = true),
                              ),
                              Expanded(
                                child: Text(
                                  note,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // 🔻 rodapé
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (q['page'] != null)
                          GestureDetector(
                            onTap: () async {
                              await TypeSelector.show(
                                context,
                                currentType: q['type'],
                                quoteId: q['id'],
                                isActive: q['is_active'] == true, // ✅ Adicionado
                                onTypeChanged: _updateQuoteType,
                              );
                            },
                            child: Text(
                              'p. ${q['page']}',
                              style:
                                  const TextStyle(color: Colors.white54),
                            ),
                          )
                        else
                          const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(
                            q['is_favorite'] == 1
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: q['is_favorite'] == 1
                                ? Colors.redAccent
                                : Colors.white54,
                          ),
                          onPressed: () async {
                            final newVal =
                                q['is_favorite'] == 1 ? 0 : 1;
                            setState(() => q['is_favorite'] = newVal);
                            await supabase
                                .from('quotes')
                                .update({'is_favorite': newVal})
                                .eq('id', q['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
