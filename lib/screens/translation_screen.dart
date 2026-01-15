import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TranslationScreen extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const TranslationScreen({
    Key? key,
    required this.vocab,
  }) : super(key: key);

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final translator = GoogleTranslator();
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String _translated = '';
  String _wordPt = '';
  String? _error;

  String get _originalText => (widget.vocab['text'] ?? '').toString().trim();
  String get _word => (widget.vocab['word'] ?? '').toString().trim();
  String get _existingTranslation =>
      (widget.vocab['translation'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();

    // ✅ CACHE HIT: já existe tradução no DB
    if (_existingTranslation.isNotEmpty) {
      print('📦 Translation loaded from DB | id=${widget.vocab['id']}');
      print('   PT: $_existingTranslation');

      _translated = _existingTranslation;

      // 🔹 garante highlight da WORD mesmo em cache hit
      if (_word.isNotEmpty) {
        translator
            .translate(_word, from: 'en', to: 'pt')
            .then((res) {
          if (!mounted) return;
          setState(() {
            _wordPt = res.text.trim();
          });
          print('🟡 WORD highlight from cache | $_word → $_wordPt');
        });
      }

      _loading = false;
    }
    else {
      _translateAndPersist();
    }
  }

  Future<void> _translateAndPersist() async {
    setState(() {
      _loading = true;
      _error = null;
      _translated = '';
      _wordPt = '';
    });

    try {
      if (_originalText.isEmpty) {
        setState(() {
          _error = 'Texto vazio';
          _loading = false;
        });
        return;
      }

      print('🌍 Translating vocabulary | id=${widget.vocab['id']}');
      print('   WORD: $_word');

      // 1) traduz o texto completo
      final resText = await translator.translate(
        _originalText,
        from: 'en',
        to: 'pt',
      );

      // 2) traduz a palavra isolada
      String wordPt = '';
      if (_word.isNotEmpty) {
        final resWord = await translator.translate(
          _word,
          from: 'en',
          to: 'pt',
        );
        wordPt = resWord.text.trim();
      }

      final translatedText = resText.text.trim();

      // 3) persiste no Supabase
      await supabase
          .from('vocabulary')
          .update({'translation': translatedText})
          .eq('id', widget.vocab['id']);

      print('💾 Translation saved | id=${widget.vocab['id']}');
      print('   PT: $translatedText');

      setState(() {
        _translated = translatedText;
        _wordPt = wordPt;
        _loading = false;
      });
    } catch (e) {
      print('❌ Translation error | id=${widget.vocab['id']} | $e');
      setState(() {
        _error = 'Falha ao traduzir: $e';
        _loading = false;
      });
    }
  }

  TextSpan _highlightedSpan({
    required String text,
    required List<String> highlights,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    if (text.isEmpty || highlights.isEmpty) {
      return TextSpan(text: text, style: normalStyle);
    }

    String? match;
    for (final h in highlights) {
      final hh = h.trim();
      if (hh.isEmpty) continue;

      final idx = text.toLowerCase().indexOf(hh.toLowerCase());
      if (idx >= 0) {
        match = hh;
        break;
      }
    }

    if (match == null) {
      return TextSpan(text: text, style: normalStyle);
    }

    final lower = text.toLowerCase();
    final lowerMatch = match.toLowerCase();
    final start = lower.indexOf(lowerMatch);
    final end = start + match.length;

    if (start < 0) {
      return TextSpan(text: text, style: normalStyle);
    }

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, start), style: normalStyle),
        TextSpan(text: text.substring(start, end), style: highlightStyle),
        TextSpan(text: text.substring(end), style: normalStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordTitle = _word.isNotEmpty ? _word : 'Tradução';

    const normalStyle = TextStyle(
      color: Colors.white,
      height: 1.35,
      fontSize: 14,
    );

    const highlightStyle = TextStyle(
      color: Colors.amberAccent,
      fontWeight: FontWeight.w700,
      height: 1.35,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(wordTitle),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Original',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: _highlightedSpan(
                  text: _originalText,
                  highlights: [_word],
                  normalStyle: normalStyle,
                  highlightStyle: highlightStyle,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tradução',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null)
                        ? Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_wordPt.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    _wordPt,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: RichText(
                                    text: _highlightedSpan(
                                      text: _translated,
                                      highlights: [_wordPt],
                                      normalStyle: normalStyle,
                                      highlightStyle: highlightStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
