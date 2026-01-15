import 'package:flutter/material.dart';
import '../utils/vocabulary_search_manager.dart';
import '../widgets/vocabulary_card.dart';
import 'translation_screen.dart';

class AnkiVocabularyScreen extends StatefulWidget {
  const AnkiVocabularyScreen({Key? key}) : super(key: key);

  @override
  State<AnkiVocabularyScreen> createState() => _AnkiVocabularyScreenState();
}

class _AnkiVocabularyScreenState extends State<AnkiVocabularyScreen> {
  final searchCtrl = TextEditingController();

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
    setState(() => isLoading = false);
  }

  void _openTranslation(Map<String, dynamic> vocab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TranslationScreen(vocab: vocab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('ANKI Mode'),
        backgroundColor: const Color(0xFF121212),
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
                  icon:
                      const Icon(Icons.clear, color: Colors.white70),
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
                      return GestureDetector(
                        onTap: () => _openTranslation(v),
                        child: VocabularyCard(
                          vocab: v,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
