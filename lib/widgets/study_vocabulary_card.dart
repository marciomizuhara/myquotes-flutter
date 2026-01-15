import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'cached_cover_image.dart';

class StudyVocabularyCard extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const StudyVocabularyCard({
    Key? key,
    required this.vocab,
  }) : super(key: key);

  @override
  State<StudyVocabularyCard> createState() => _StudyVocabularyCardState();
}

class _StudyVocabularyCardState extends State<StudyVocabularyCard> {
  final translator = GoogleTranslator();

  String _wordPt = '';
  bool _loadingWordPt = false;

  String get _word => (widget.vocab['word'] ?? '').toString().trim();
  String get _textEn => (widget.vocab['text'] ?? '').toString().trim();
  String get _textPt => (widget.vocab['translation'] ?? '').toString().trim();

  Map<String, dynamic> get _book =>
      (widget.vocab['books'] is Map<String, dynamic>)
          ? widget.vocab['books']
          : {};

  String get _cover => (_book['cover'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadWordPt();
  }

  Future<void> _loadWordPt() async {
    if (_loadingWordPt) return;

    final w = _word;
    if (w.isEmpty) return;

    setState(() => _loadingWordPt = true);

    try {
      final res = await translator.translate(w, from: 'en', to: 'pt');
      final pt = res.text.trim();

      if (!mounted) return;

      setState(() {
        _wordPt = pt;
        _loadingWordPt = false;
      });

      // print('🟡 STUDY highlight word | $w → $_wordPt');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWordPt = false);
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
    const normalEnStyle = TextStyle(
      color: Colors.white,
      height: 1.35,
      fontSize: 14,
    );

    const normalPtStyle = TextStyle(
      color: Colors.white70,
      height: 1.35,
      fontSize: 13,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
    );

    const highlightPtStyle = TextStyle(
      color: Colors.amberAccent,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      height: 1.35,
      fontSize: 13,
    );

    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_cover.isNotEmpty)
              CachedCoverImage(
                url: _cover,
                width: 46,
                height: 68,
                borderRadius: BorderRadius.circular(6),
              ),
            if (_cover.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_word.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _word,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),

                  // ✅ EN: full branco, sem highlight
                  if (_textEn.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _textEn,
                        style: normalEnStyle,
                      ),
                    ),

                  // ✅ PT: highlight só da palavra traduzida (_wordPt)
                  if (_textPt.isNotEmpty)
                    (_wordPt.isNotEmpty &&
                            _textPt
                                .toLowerCase()
                                .contains(_wordPt.toLowerCase()))
                        ? RichText(
                            text: _highlightedSpan(
                              text: _textPt,
                              highlights: [_wordPt],
                              normalStyle: normalPtStyle,
                              highlightStyle: highlightPtStyle,
                            ),
                          )
                        : Text(
                            _textPt,
                            style: normalPtStyle,
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
