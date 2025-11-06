import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  static Map<String, dynamic>? _cachedQuote; // cache leve por sessão
  static String? _cachedDate;

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
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());

    // 🔹 Reutiliza a mesma quote dentro do mesmo dia
    if (_cachedQuote != null && _cachedDate == today) {
      setState(() {
        _quote = _cachedQuote;
        _loading = false;
      });
      _controller.forward(from: 0);
      return;
    }

    try {
      setState(() => _loading = true);

      final allQuotes = await QuotesHelper.fetchQuotes();
      if (allQuotes.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // 🔹 Determinística por data (sem persistência)
      final seed = int.parse(today);
      final random = Random(seed);
      final index = random.nextInt(allQuotes.length);
      final q = allQuotes[index];

      final normalized = {
        'id': q['id'],
        'text': q['text'] ?? '',
        'notes': q['notes'] ?? '',
        'is_favorite': (q['is_favorite'] ?? 0) == 1 ? 1 : 0,
        'page': q['page'],
        'type': q['type'],
        'books': q['books'] ??
            {
              'title': q['book_title'] ?? '',
              'author': q['book_author'] ?? '',
              'cover': q['book_cover'] ?? '',
            },
      };

      _cachedQuote = normalized;
      _cachedDate = today;

      setState(() {
        _quote = normalized;
        _loading = false;
      });
      _controller.forward(from: 0);
    } catch (e) {
      debugPrint('❌ Erro ao carregar Quote of the Day: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                                    width: 230,
                                    height: 340,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) =>
                                        Container(
                                      width: 230,
                                      height: 340,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 36),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                q['text'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  height: 1.8,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 19,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              author,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🔹 Rodapé
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q['page'] != null ? 'p. ${q['page']}' : '',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
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
