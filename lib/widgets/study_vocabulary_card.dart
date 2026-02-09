import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cached_cover_image.dart';

class StudyVocabularyCard extends StatefulWidget {
  final Map<String, dynamic> vocab;
  final bool showTranslation;
  final bool enableCrud;

  const StudyVocabularyCard({
    Key? key,
    required this.vocab,
    this.showTranslation = true,
    this.enableCrud = true,
  }) : super(key: key);

  @override
  State<StudyVocabularyCard> createState() => _StudyVocabularyCardState();
}

class _StudyVocabularyCardState extends State<StudyVocabularyCard> {
  final translator = GoogleTranslator();
  final supabase = Supabase.instance.client;

  String _wordPt = '';
  bool _loadingWordPt = false;

  bool _editingWord = false;
  bool _editingEn = false;
  bool _editingPt = false;

  late TextEditingController _wordCtrl;
  late TextEditingController _enCtrl;
  late TextEditingController _ptCtrl;
  late TextEditingController _translatedWordCtrl;

  String get _word => (widget.vocab['word'] ?? '').toString().trim();
  String get _textEn => (widget.vocab['text'] ?? '').toString().trim();
  String get _textPt => (widget.vocab['translation'] ?? '').toString().trim();
  String get _status => (widget.vocab['status'] ?? '').toString().trim();

  List<String> get _ptHighlights {
    final forced = (widget.vocab['translated_word'] ?? '').toString().trim();

    if (forced.isNotEmpty) {
      return forced
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (_wordPt.isNotEmpty) {
      return [_wordPt];
    }

    return [];
  }


  Map<String, dynamic> get _book =>
      (widget.vocab['books'] is Map<String, dynamic>)
          ? widget.vocab['books']
          : {};

  String get _cover => (_book['cover'] ?? '').toString();

  Color _statusBorderColor() {
    switch (_status) {
      case 'again':
        return Colors.red.shade700;
      case 'hard':
        return Colors.orange.shade700;
      case 'good':
        return Colors.amberAccent;
      case 'easy':
        return Colors.green.shade700;
      default:
        return Colors.transparent;
    }
  }

  @override
  void initState() {
    super.initState();

    _wordCtrl = TextEditingController(text: _word);
    _enCtrl = TextEditingController(text: _textEn);
    _ptCtrl = TextEditingController(text: _textPt);
    _translatedWordCtrl = TextEditingController(
      text: (widget.vocab['translated_word'] ?? '').toString(),
    );

    _loadWordPt();
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _enCtrl.dispose();
    _ptCtrl.dispose();
    _translatedWordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWordPt() async {
    if (_loadingWordPt || _word.isEmpty) return;

    setState(() => _loadingWordPt = true);

    try {
      final res = await translator.translate(_word, from: 'en', to: 'pt');
      if (!mounted) return;

      setState(() {
        _wordPt = res.text.trim();
        _loadingWordPt = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWordPt = false);
    }
  }

  Future<void> _saveWord() async {
    final text = _wordCtrl.text.trim();
    if (text.isEmpty) return;

    await supabase
        .from('vocabulary')
        .update({'word': text})
        .eq('id', widget.vocab['id']);

    widget.vocab['word'] = text;
    setState(() => _editingWord = false);
  }

  Future<void> _saveEn() async {
    final text = _enCtrl.text.trim();

    await supabase
        .from('vocabulary')
        .update({'text': text})
        .eq('id', widget.vocab['id']);

    widget.vocab['text'] = text;
    setState(() => _editingEn = false);
  }

  Future<void> _savePt() async {
    final text = _ptCtrl.text.trim();
    final forced = _translatedWordCtrl.text.trim();

    await supabase.from('vocabulary').update({
      'translation': text,
      'translated_word': forced.isEmpty ? null : forced,
    }).eq('id', widget.vocab['id']);

    widget.vocab['translation'] = text;
    widget.vocab['translated_word'] = forced;
    setState(() => _editingPt = false);
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
    final start = lower.indexOf(match.toLowerCase());
    final end = start + match.length;

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
    const wordStyle = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    const normalEnStyle = TextStyle(
      color: Colors.white,
      height: 1.2,
      fontSize: 14,
    );

    const normalPtStyle = TextStyle(
      color: Colors.white70,
      height: 1.2,
      fontSize: 13,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
    );

    const highlightStyle = TextStyle(
      color: Colors.amberAccent,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    const forcedHighlightInputStyle = TextStyle(
      color: Colors.amberAccent,
      fontWeight: FontWeight.w600,
    );


    final borderColor = _statusBorderColor();

    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: widget.showTranslation
            ? BorderSide.none
            : BorderSide(
                color: borderColor,
                width: borderColor == Colors.transparent ? 0 : 2,
              ),
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
                  // TERMO
                  if (_word.isNotEmpty)
                    GestureDetector(
                      onLongPress: widget.enableCrud
                          ? () => setState(() => _editingWord = true)
                          : null,
                      child: Row(
                        children: [
                          Expanded(
                            child: _editingWord
                                ? TextField(
                                    controller: _wordCtrl,
                                    style: wordStyle,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                  )
                                : Text(
                                    _word.toUpperCase(),
                                    style: wordStyle,
                                  ),
                          ),
                          if (_editingWord)
                            IconButton(
                              icon: const Icon(Icons.check, size: 18),
                              color: Colors.amberAccent,
                              onPressed: _saveWord,
                            ),
                        ],
                      ),
                    ),

                  // EN
                  if (_textEn.isNotEmpty)
                    GestureDetector(
                      onLongPress: widget.enableCrud
                          ? () => setState(() => _editingEn = true)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _editingEn
                                ? TextField(
                                    controller: _enCtrl,
                                    maxLines: null,
                                    style: normalEnStyle,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                  )
                                : Text.rich(
                                    _highlightedSpan(
                                      text: _textEn,
                                      highlights: [_word],
                                      normalStyle: normalEnStyle,
                                      highlightStyle: highlightStyle,
                                    ),
                                  ),
                          ),
                          if (_editingEn)
                            IconButton(
                              icon: const Icon(Icons.check, size: 18),
                              color: Colors.amberAccent,
                              onPressed: _saveEn,
                            ),
                        ],
                      ),
                    ),

                  // PT
                  if (widget.showTranslation && _textPt.isNotEmpty)
                    GestureDetector(
                      onLongPress: widget.enableCrud
                          ? () => setState(() => _editingPt = true)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _editingPt
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _ptCtrl,
                                        maxLines: null,
                                        style: normalPtStyle,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                      TextField(
                                        controller: _translatedWordCtrl,
                                        style: forcedHighlightInputStyle,
                                        decoration: const InputDecoration(
                                          hintText: 'termo a destacar',
                                          hintStyle: TextStyle(color: Colors.white38),
                                          isDense: true,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text.rich(
                                    _highlightedSpan(
                                      text: _textPt,
                                      highlights: _ptHighlights,
                                      normalStyle: normalPtStyle,
                                      highlightStyle: highlightStyle.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                          ),
                          if (_editingPt)
                            IconButton(
                              icon: const Icon(Icons.check, size: 18),
                              color: Colors.amberAccent,
                              onPressed: _savePt,
                            ),
                        ],
                      ),
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
