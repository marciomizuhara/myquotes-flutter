import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card.dart';
import '../widgets/type_selector.dart';
import '../utils/quotes_search_manager.dart';     //  ✅ NOVO
import '../utils/quotes_cache_manager.dart';

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

  String _sortMode = 'random';
  static const _globalCacheKey = 'quotes_global_cache_v1';
  static bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runSearch();
      _hasLoadedOnce = true;
    });
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    quotes = await QuotesSearchManager.search(
      origin: 'global',
      rawTerm: searchCtrl.text,
      typeFilter: selectedType,
      sortMode: _sortMode,
      cacheKey: _globalCacheKey,
      forceRefresh: forceRefresh,
    );

    setState(() => isLoading = false);
  }

  void _changeSortMode(String mode) async {
    setState(() => _sortMode = mode);
    _runSearch();
  }

  void _copyQuote(Map<String, dynamic> q) {
    final text = q['text'] ?? '';
    final author = q['books']?['author'] ?? 'Autor desconhecido';
    final title = q['books']?['title'] ?? 'Livro não informado';
    final formatted = '$text\n\npor $author, em $title';

    Clipboard.setData(ClipboardData(text: formatted));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Citação copiada!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
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
        width: 22,
        height: 22,
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
            // 🔍 Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                onSubmitted: (term) => _runSearch(),
              ),
            ),

            // 🎨 Bolinhas + ações
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _typeDot(1, red),
                  _typeDot(2, yellow),
                  _typeDot(3, green),
                  _typeDot(4, blue),
                  _typeDot(5, cyan),
                  _typeDot(6, gray),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Recarregar do Supabase',
                    onPressed: () async {
                      await QuotesCacheManager.clearCache(_globalCacheKey);
                      await _runSearch(forceRefresh: true);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    onPressed: () => _changeSortMode('random'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    onPressed: () => _changeSortMode('one_per_book_desc'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 📜 Lista
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await QuotesCacheManager.clearCache(_globalCacheKey);
                        await _runSearch(forceRefresh: true);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: quotes.length,
                        itemBuilder: (context, i) {
                          final q = quotes[i];
                          return QuoteCard(
                            quote: q,
                            onFavoriteChanged: () async {
                              setState(() {
                                quotes[i]['is_favorite'] =
                                    quotes[i]['is_favorite'] == 1 ? 0 : 1;
                              });

                              await QuotesCacheManager.saveQuotes(
                                _globalCacheKey,
                                quotes,
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
