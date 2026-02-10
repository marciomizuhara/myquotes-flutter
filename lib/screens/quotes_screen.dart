import 'package:flutter/material.dart';
import '../widgets/quote_card/quote_card.dart';
import '../widgets/quotes_top_controls.dart';
import '../utils/quotes_search_manager.dart';
import '../utils/quotes_cache_manager.dart';
import 'anki_vocabulary_screen.dart';
import 'study_vocabulary_screen.dart';


class QuotesScreen extends StatefulWidget {
  const QuotesScreen({Key? key}) : super(key: key);

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;

  bool _showInactive = false;
  String _sortMode = 'random';

  static const _activeCacheKey = 'quotes_global_active_cache_v1';
  static bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runSearch(forceRefresh: !_hasLoadedOnce);
      _hasLoadedOnce = true;
    });
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    List<Map<String, dynamic>> result;

    if (_showInactive) {
      debugPrint('🔎 BUSCA: modo ARQUIVO (inativas)');

      result = await QuotesSearchManager.search(
        origin: 'global',
        rawTerm: searchCtrl.text,
        typeFilter: selectedType,
        sortMode: _sortMode,
        cacheKey: 'archive_mode_tmp',
        forceRefresh: true,
        onlyActive: false,
      );

      result = result.where((q) {
        final a = q['is_active'];
        return a == 0 || a == false || a == '0';
      }).toList();

      debugPrint('📦 Inativas encontradas: ${result.length}');
    } else {
      debugPrint('⚡ BUSCA: modo NORMAL (ativas + cache)');

      result = await QuotesSearchManager.search(
        origin: 'global',
        rawTerm: searchCtrl.text,
        typeFilter: selectedType,
        sortMode: _sortMode,
        cacheKey: _activeCacheKey,
        forceRefresh: forceRefresh,
        onlyActive: true,
      );

      if (_sortMode == 'random') {
        result.shuffle();
      }

      debugPrint('⚡ Ativas carregadas: ${result.length}');
    }

    quotes = result;
    setState(() => isLoading = false);
  }

  void _toggleArchiveMode() async {
    setState(() {
      _showInactive = !_showInactive;
      selectedType = null;
    });

    await _runSearch(forceRefresh: _showInactive);
  }

  void _openAnki() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnkiVocabularyScreen(),
      ),
    );
  }

  void _openStudy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudyVocabularyScreen(),
      ),
    );
  }


  void _changeSortMode(String mode) async {
    setState(() => _sortMode = mode);
    await _runSearch();
  }

  Widget _compactIcon({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white70,
  }) {
    return SizedBox(
      width: 32,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedType = active ? null : t;
        });
        await _runSearch();
      },
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(
            color: active ? Colors.amber : Colors.white24,
            width: active ? 2 : 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFF9B2C2C);
    const yellow = Color(0xFFB8961A);
    const green = Color(0xFF2F7D32);
    const blue = Color(0xFF275D8C);
    const cyan = Color(0xFF118EA8);
    const gray = Color(0xFF5A5A5A);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
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
                      selectedType = null;
                      FocusScope.of(context).unfocus();
                      await _runSearch();
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _runSearch(),
              ),
            ),

            QuotesTopControls(
              typeDots: [
                _typeDot(1, red),
                _typeDot(2, yellow),
                _typeDot(3, green),
                _typeDot(4, blue),
                _typeDot(5, cyan),
                _typeDot(6, gray),
              ],
              leadingAction: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _compactIcon(
                    icon: Icons.menu_book, // 📘 STUDY
                    color: Colors.white38,
                    onPressed: _openStudy,
                  ),
                  _compactIcon(
                    icon: Icons.school, // 🎓 ANKI
                    color: Colors.white38,
                    onPressed: _openAnki,
                  ),
                  _compactIcon(
                      icon: _showInactive
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _showInactive
                          ? Colors.amber
                          : Colors.white38,
                      onPressed: _toggleArchiveMode,
                  ),
                ],
              ),
              trailingActions: [
                _compactIcon(
                  icon: Icons.refresh,
                  onPressed: () async {
                    await QuotesCacheManager.clearCache(
                        _activeCacheKey);
                    await _runSearch(forceRefresh: true);
                  },
                ),
                _compactIcon(
                  icon: Icons.shuffle,
                  onPressed: () =>
                      _changeSortMode('random'),
                ),
                _compactIcon(
                  icon: Icons.arrow_upward,
                  onPressed: () =>
                      _changeSortMode('one_per_book_desc'),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: quotes.length,
                      itemBuilder: (context, i) {
                        final q = quotes[i];
                        return QuoteCard(
                          quote: q,
                          onFavoriteChanged: () async {
                            setState(() {
                              quotes[i]['is_favorite'] =
                                  quotes[i]['is_favorite'] == 1
                                      ? 0
                                      : 1;
                            });
                            await QuotesCacheManager.saveQuotes(
                              _activeCacheKey,
                              quotes,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
