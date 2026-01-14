import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

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

  bool _loading = true;
  String _translated = '';
  String _wordPt = '';
  String? _error;

  String get _originalText => (widget.vocab['text'] ?? '').toString().trim();
  String get _word => (widget.vocab['word'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
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

      // 1) traduz a frase
      final resText = await translator.translate(
        _originalText,
        from: 'en',
        to: 'pt',
      );

      // 2) traduz a WORD separadamente (melhor pra destacar)
      String wordPt = '';
      if (_word.isNotEmpty) {
        final resWord = await translator.translate(
          _word,
          from: 'en',
          to: 'pt',
        );
        wordPt = resWord.text.trim();
      }

      setState(() {
        _translated = resText.text.trim();
        _wordPt = wordPt;
        _loading = false;
      });
    } catch (e) {
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

    // tenta achar o primeiro highlight que aparece
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
                                  padding: const EdgeInsets.only(bottom: 10),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _translate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Traduzir novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
