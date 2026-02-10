import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card/quote_card.dart';
import '../widgets/quotes_top_controls.dart';
import '../utils/quotes_cache_manager.dart';
import '../utils/quotes_search_manager.dart';

class FavoriteQuotesScreen extends StatefulWidget {
  const FavoriteQuotesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteQuotesScreen> createState() =>
      _FavoriteQuotesScreenState();
}

class _FavoriteQuotesScreenState extends State<FavoriteQuotesScreen> {
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;

  String _sortMode = 'random';
  static const _favoritesCacheKey = 'favorites_cache_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runSearch();
    });
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    var result = await QuotesSearchManager.search(
      origin: 'favorites',
      rawTerm: searchCtrl.text,
      typeFilter: selectedType,
      sortMode: _sortMode,
      cacheKey: _favoritesCacheKey,
      forceRefresh: forceRefresh,
      onlyActive: true,
    );

    result.shuffle();
    quotes = result;

    setState(() => isLoading = false);
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
              trailingActions: [
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Recarregar favoritos',
                  onPressed: () async {
                    await QuotesCacheManager.clearCache(
                        _favoritesCacheKey);
                    await _runSearch(forceRefresh: true);
                  },
                ),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.shuffle, color: Colors.white70),
                  onPressed: () => _runSearch(),
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
                              _favoritesCacheKey,
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
