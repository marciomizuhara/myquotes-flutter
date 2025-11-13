import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';
import '../utils/quotes_helper.dart';
import '../widgets/type_selector.dart';

class QuoteOfTheDayScreen extends StatefulWidget {
  const QuoteOfTheDayScreen({Key? key}) : super(key: key);

  @override
  State<QuoteOfTheDayScreen> createState() => _QuoteOfTheDayScreenState();
}

class _QuoteOfTheDayScreenState extends State<QuoteOfTheDayScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _quote;
  bool _loading = true;

  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _notesCtrl = TextEditingController();
  bool _editingNote = false;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fetchQuoteOfTheDay();
  }

  Future<void> _fetchQuoteOfTheDay() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    setState(() => _loading = true);

    try {
      final existing = await supabase
          .from('quote_of_the_day')
          .select('quote_id, date_key')
          .eq('date_key', today)
          .order('created_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        final quoteId = existing.first['quote_id'];

        final res = await supabase
            .from('quotes')
            .select('id, text, notes, is_favorite, page, type, books(title, author, cover)')
            .eq('id', quoteId)
            .maybeSingle();

        if (res != null) {
          setState(() {
            _quote = Map<String, dynamic>.from(res);
            _notesCtrl.text = _quote?['notes'] ?? '';
            _loading = false;
          });
          _controller.forward(from: 0);
          return;
        }
      }

      final allQuotes = await QuotesHelper.fetchQuotes();
      if (allQuotes.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final seed = int.parse(today);
      final random = Random(seed);
      final index = random.nextInt(allQuotes.length);
      final q = allQuotes[index];

      await supabase.from('quote_of_the_day').insert({
        'quote_id': q['id'],
        'date_key': today,
      });

      setState(() {
        _quote = q;
        _notesCtrl.text = q['notes'] ?? '';
        _loading = false;
      });
      _controller.forward(from: 0);
    } catch (e) {
      debugPrint('❌ Erro ao buscar/registrar Quote do Dia: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQuoteType(int newType) async {
    try {
      await supabase
          .from('quotes')
          .update({'type': newType})
          .eq('id', _quote?['id']);
      setState(() => _quote?['type'] = newType);
    } catch (e) {
      debugPrint('❌ Erro ao atualizar tipo: $e');
    }
  }

  Future<void> _updateNotes(String newText) async {
    if (_savingNote || _quote == null) return;
    setState(() => _savingNote = true);
    try {
      await supabase
          .from('quotes')
          .update({'notes': newText})
          .eq('id', _quote!['id']);
      setState(() => _quote!['notes'] = newText);
    } catch (e) {
      debugPrint('❌ Erro ao salvar nota: $e');
    } finally {
      setState(() => _savingNote = false);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_quote == null) {
      return const Center(child: Text('Nenhuma citação disponível.'));
    }

    final q = _quote!;
    final book = q['books'] ?? {};
    final bgColor = colorByType(q['type']);
    final cover = (book['cover'] ?? '').toString();
    final title = (book['title'] ?? '').toString();
    final author = (book['author'] ?? '').toString();
    final note = _notesCtrl.text.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor.withOpacity(0.85), Colors.black.withOpacity(0.9)],
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
                  // 🔹 A quote ocupa o espaço central
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: GestureDetector(
                        onDoubleTap: () => _copyQuote(q),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (cover.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 16,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    cover,
                                    width: 160,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => Container(
                                      width: 160,
                                      height: 220,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                q['text'] ?? '',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                ),
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
                  ),

                  // 🔹 bloco de notas movido para perto do rodapé
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: _editingNote
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _notesCtrl,
                                  maxLines: null,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Editar nota...',
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green, size: 20),
                                onPressed: () async {
                                  final newText = _notesCtrl.text.trim();
                                  await _updateNotes(newText);
                                  setState(() => _editingNote = false);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _notesCtrl.text = note;
                                    _editingNote = false;
                                  });
                                },
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note,
                                    color: Colors.white70, size: 20),
                                onPressed: () => setState(() => _editingNote = true),
                              ),
                              Expanded(
                                child: Text(
                                  note.isEmpty ? '' : note,
                                  style: TextStyle(
                                    color: note.isEmpty
                                        ? Colors.white38
                                        : Colors.white70,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // 🔹 rodapé fixo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (q['page'] != null)
                          GestureDetector(
                            onTap: () async {
                              final int type =
                                  (q['type'] is int) ? q['type'] : int.tryParse(q['type'].toString()) ?? 0;

                              await TypeSelector.show(
                                context,
                                currentType: type,
                                quoteId: q['id'],
                                onTypeChanged: (newType) async {
                                  await _updateQuoteType(newType);
                                  setState(() => _quote?['type'] = newType);
                                },
                              );
                            },
                            child: Text(
                              'p. ${q['page']}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 24),

                        IconButton(
                          icon: Icon(
                            (q['is_favorite'] == 1) ? Icons.favorite : Icons.favorite_border,
                            color: (q['is_favorite'] == 1)
                                ? Colors.redAccent
                                : Colors.white54,
                            size: 28,
                          ),
                          onPressed: () async {
                            final newVal = q['is_favorite'] == 1 ? 0 : 1;
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
