import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card.dart';
import '../widgets/type_selector.dart';
import '../widgets/quotes_top_controls.dart';
import '../utils/quotes_search_manager.dart';
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

  bool _showInactive = false;

  String _sortMode = 'random';
  static const _globalCacheKey = 'quotes_global_cache_v1';
  static bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runSearch(forceRefresh: true);
      _hasLoadedOnce = true;
    });
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    var result = await QuotesSearchManager.search(
      origin: 'global',
      rawTerm: searchCtrl.text,
      typeFilter: selectedType,
      sortMode: _sortMode,
      cacheKey: _globalCacheKey,
      forceRefresh: forceRefresh,
      onlyActive: !_showInactive,
    );

    if (_showInactive) {
      result = result.where((q) {
        final a = q['is_active'];
        return a == false || a == 0 || a == '0';
      }).toList();

      if (result.length < 2) {
        final remote = await QuotesSearchManager.search(
          origin: 'global',
          rawTerm: searchCtrl.text,
          typeFilter: selectedType,
          sortMode: _sortMode,
          cacheKey: _globalCacheKey,
          forceRefresh: true,
          onlyActive: false,
        );

        result = remote.where((q) {
          final a = q['is_active'];
          return a == false || a == 0 || a == '0';
        }).toList();
      }
    }

    if (_sortMode == 'random' && !_showInactive) {
      result.shuffle();
    }

    quotes = result;
    setState(() => isLoading = false);
  }

  void _toggleArchiveMode() async {
    setState(() {
      _showInactive = !_showInactive;
      selectedType = null;
    });
    await _runSearch(forceRefresh: true);
  }

  void _changeSortMode(String mode) async {
    setState(() => _sortMode = mode);
    _runSearch();
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
              leadingAction: IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _showInactive
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color:
                      _showInactive ? Colors.amber : Colors.white38,
                ),
                onPressed: _toggleArchiveMode,
              ),
              trailingActions: [
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () async {
                    await QuotesCacheManager.clearCache(
                        _globalCacheKey);
                    await _runSearch(forceRefresh: true);
                  },
                ),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.shuffle, color: Colors.white70),
                  onPressed: () =>
                      _changeSortMode('random'),
                ),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_upward,
                      color: Colors.white70),
                  onPressed: () =>
                      _changeSortMode('one_per_book_desc'),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await QuotesCacheManager.clearCache(
                            _globalCacheKey);
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
                                    quotes[i]['is_favorite'] == 1
                                        ? 0
                                        : 1;
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
