import 'package:flutter/material.dart';
import '../utils/vocabulary_search_manager.dart';
import '../widgets/study_vocabulary_card.dart';
import 'anki_card_screen.dart';
import 'study_vocabulary_screen.dart';


class AnkiVocabularyScreen extends StatefulWidget {
  const AnkiVocabularyScreen({Key? key}) : super(key: key);

  @override
  State<AnkiVocabularyScreen> createState() =>
      _AnkiVocabularyScreenState();
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

  void _openStudy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudyVocabularyScreen(),
      ),
    );
  }


  Future<void> _loadVocabulary() async {
    setState(() => isLoading = true);

    final result = await VocabularySearchManager.search(
      rawTerm: searchCtrl.text,
    );

    vocabulary = result;
    setState(() => isLoading = false);
  }

  Future<void> _openTranslation(Map<String, dynamic> vocab) async {
    final newStatus = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AnkiCardScreen(vocab: vocab),
      ),
    );

    if (newStatus != null) {
      setState(() {
        vocab['status'] = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('ANKI Mode'),
        backgroundColor: const Color(0xFF121212),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book), // 📖 Study
            tooltip: 'Study vocabulary',
            onPressed: _openStudy,
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
                        child: StudyVocabularyCard(
                          vocab: v,
                          showTranslation: false,
                          enableCrud: false,
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
