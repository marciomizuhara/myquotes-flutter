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
  static Map<String, dynamic>? _cachedQuote;
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

  Future<void> _showTypeSelector(BuildContext context, int currentType) async {
    final colors = {
      1: const Color(0xFF9B2C2C),
      2: const Color(0xFFB8961A),
      3: const Color(0xFF2F7D32),
      4: const Color(0xFF275D8C),
      5: const Color(0xFF118EA8),
      6: const Color(0xFF5A5A5A),
    };

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.entries.map((entry) {
              final isActive = entry.key == currentType;
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _updateQuoteType(entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 28 : 22,
                  height: isActive ? 28 : 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.value,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: entry.value.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
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

  int _safeType(dynamic rawType) {
    if (rawType == null) return 0;
    if (rawType is int) return rawType;
    if (rawType is num) return rawType.toInt();
    return int.tryParse(rawType.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_quote == null) return const Center(child: Text('Nenhuma citação disponível.'));

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
                                    width: 200,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => Container(
                                      width: 210,
                                      height: 280,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 36),
                            // 🔹 Citação adaptável e truncável
                            LayoutBuilder(
                              builder: (context, constraints) {
                                double fontSize = 28;
                                const double minFontSize = 18;
                                const int maxLines = 10;

                                final text = q['text'] ?? '';
                                if (text.length > 400) fontSize = 24;
                                if (text.length > 600) fontSize = 22;
                                if (text.length > 800) fontSize = 20;
                                if (text.length > 1000) fontSize = minFontSize;

                                final displayText = text.length > 1200
                                    ? '${text.substring(0, 1150).trim()}...'
                                    : text;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Text(
                                    displayText,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.fade,
                                    maxLines: maxLines,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.white,
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 36),
                            // 🔹 Título adaptável refinado e autor sempre visível
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final titleText = title.trim();
                                double fontSize = 24;
                                const double minFontSize = 16;

                                if (titleText.length > 30) fontSize = 22;
                                if (titleText.length > 50) fontSize = 20;
                                if (titleText.length > 70) fontSize = 18;
                                if (titleText.length > 90) fontSize = minFontSize;

                                final displayTitle = titleText.length > 100
                                    ? '${titleText.substring(0, 95).trim()}...'
                                    : titleText;

                                return Column(
                                  children: [
                                    Text(
                                      displayTitle,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: fontSize - 4, // 🔹 leve redução
                                        color: Colors.amberAccent,
                                        fontWeight: FontWeight.w500, // 🔹 suaviza peso
                                        height: 1.25,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (author.isNotEmpty)
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
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (q['page'] != null)
                        GestureDetector(
                          onTap: () => _showTypeSelector(context, _safeType(q['type'])),
                          child: Text(
                            'p. ${q['page']}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
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
