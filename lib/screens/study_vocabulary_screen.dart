import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/vocabulary_search_manager.dart';
import '../widgets/study_vocabulary_card.dart';
import '../utils/translation_service.dart';
import 'anki_vocabulary_screen.dart';

class StudyVocabularyScreen extends StatefulWidget {
  const StudyVocabularyScreen({Key? key}) : super(key: key);

  @override
  State<StudyVocabularyScreen> createState() =>
      _StudyVocabularyScreenState();
}

class _StudyVocabularyScreenState extends State<StudyVocabularyScreen> {
  final searchCtrl = TextEditingController();
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> vocabulary = [];

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    setState(() => isLoading = true);

    final result = await VocabularySearchManager.search(
      rawTerm: searchCtrl.text,
    );

    vocabulary = result;

    // 🔹 garante que todas tenham tradução persistida
    await _populateMissingTranslations(vocabulary);

    setState(() => isLoading = false);
  }

  Future<void> _populateMissingTranslations(
    List<Map<String, dynamic>> items,
  ) async {
    for (final v in items) {
      final id = v['id'];
      final textEn = (v['text'] ?? '').toString().trim();
      final existingPt =
          (v['translation'] ?? '').toString().trim();

      if (textEn.isEmpty || existingPt.isNotEmpty) {
        continue;
      }

      try {
        print('🌍 STUDY ETL | Translating id=$id');

        final pt = await TranslationService.translateToPtBr(
          text: textEn,
        );

        await supabase
            .from('vocabulary')
            .update({'translation': pt})
            .eq('id', id);

        v['translation'] = pt;

        print('💾 STUDY ETL | Saved translation id=$id');
      } catch (e) {
        print('❌ STUDY ETL | Failed id=$id | $e');
      }
    }
  }

  void _openAnkiMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnkiVocabularyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('STUDY Mode'),
        backgroundColor: const Color(0xFF121212),
        actions: [
          IconButton(
            tooltip: 'ANKI Mode',
            icon: const Icon(Icons.school_outlined),
            onPressed: vocabulary.isEmpty ? null : _openAnkiMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () async {
                    searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                    await _loadVocabulary();
                  },
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadVocabulary(),
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: vocabulary.length,
                    itemBuilder: (context, i) {
                      final v = vocabulary[i];
                      return StudyVocabularyCard(vocab: v);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
