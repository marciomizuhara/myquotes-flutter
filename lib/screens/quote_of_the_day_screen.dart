import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';
import '../utils/quotes_helper.dart';

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
      // 🔹 1️⃣ Verifica se já há quote registrada para o dia
      final existing = await supabase
          .from('quote_of_the_day')
          .select('quote_id, date_key')
          .eq('date_key', today)
          .order('created_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        final quoteId = existing.first['quote_id'];
        debugPrint('📆 Quote já existente para $today → ID $quoteId');

        // 🔹 2️⃣ Busca a quote correspondente
        final res = await supabase
            .from('quotes')
            .select('id, text, notes, is_favorite, page, type, books(title, author, cover)')
            .eq('id', quoteId)
            .maybeSingle();

        if (res != null) {
          setState(() {
            _quote = Map<String, dynamic>.from(res);
            _loading = false;
          });
          _controller.forward(from: 0);
          return;
        }
      }

      // 🔹 3️⃣ Nenhum registro encontrado → seleciona nova quote aleatória
      final allQuotes = await QuotesHelper.fetchQuotes();
      if (allQuotes.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final seed = int.parse(today);
      final random = Random(seed);
      final index = random.nextInt(allQuotes.length);
      final q = allQuotes[index];

      // 🔹 4️⃣ Registra nova quote do dia
      await supabase.from('quote_of_the_day').insert({
        'quote_id': q['id'],
        'date_key': today,
      });

      debugPrint('🆕 Nova Quote do Dia registrada → ID ${q['id']} para $today');

      setState(() {
        _quote = q;
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
      setState(() {
        _quote?['type'] = newType;
      });
      debugPrint('🟢 Tipo da quote atualizado para $newType');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar tipo: $e');
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      errorBuilder: (context, _, __) =>
                                          Container(width: 160, height: 220, color: Colors.black26),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 36),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                              const SizedBox(height: 36),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
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
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (q['page'] != null)
                        Text(
                          'p. ${q['page']}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          (q['is_favorite'] == 1)
                              ? Icons.favorite
                              : Icons.favorite_border,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
