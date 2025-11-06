import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/quote_card.dart';

class FavoriteQuotesScreen extends StatefulWidget {
  const FavoriteQuotesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteQuotesScreen> createState() => _FavoriteQuotesScreenState();
}

class _FavoriteQuotesScreenState extends State<FavoriteQuotesScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;
  String _sortMode = 'random';

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites({String? term}) async {
    setState(() => isLoading = true);

    try {
      final query = supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, book_id, books(title, author, cover)',
          )
          .eq('is_favorite', 1);

      if (term != null && term.trim().isNotEmpty) {
        query.ilike('text', '%${term.trim()}%');
      }

      if (selectedType != null) {
        query.eq('type', selectedType!);
      }

      query.order('id', ascending: true);

      final res = await query;
      final data = (res as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      debugPrint('💛 FetchFavorites → ${data.length} favoritas recebidas');

      // 🔹 Ordenação local
      if (_sortMode == 'newest') {
        data.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      } else if (_sortMode == 'oldest') {
        data.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      } else if (_sortMode == 'random') {
        data.shuffle();
      }

      for (var q in data.take(5)) {
        debugPrint('💛 id=${q['id']} | type=${q['type']} | fav=${q['is_favorite']}');
      }

      setState(() {
        quotes = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro em _fetchFavorites: $e');
      setState(() => isLoading = false);
    }
  }

  void _changeSortMode(String mode) {
    setState(() => _sortMode = mode);
    _fetchFavorites(term: searchCtrl.text.isEmpty ? null : searchCtrl.text);
  }

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = active ? null : t;
        });
        _fetchFavorites(term: searchCtrl.text);
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
    const gray = Color(0xFF5A5A5A); // 🆕 tipo 6 (cinza)

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
                  hintText: 'Pesquisar citações favoritas...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      searchCtrl.clear();
                      selectedType = null;
                      FocusScope.of(context).unfocus();
                      _fetchFavorites();
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onSubmitted: (term) => _fetchFavorites(term: term),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _typeDot(1, red),
                  _typeDot(2, yellow),
                  _typeDot(3, green),
                  _typeDot(4, blue),
                  _typeDot(5, cyan),
                  _typeDot(6, gray), // 🆕 bolinha cinza adicionada
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                    tooltip: 'Mais antigas',
                    onPressed: () => _changeSortMode('oldest'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    tooltip: 'Aleatórias',
                    onPressed: () => _changeSortMode('random'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    tooltip: 'Mais recentes',
                    onPressed: () => _changeSortMode('newest'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : quotes.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma citação marcada como favorita.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchFavorites(
                            term: searchCtrl.text.isEmpty
                                ? null
                                : searchCtrl.text,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: quotes.length,
                            itemBuilder: (context, i) => QuoteCard(
                              quote: quotes[i],
                              onFavoriteChanged: () async {
                                if ((quotes[i]['is_favorite'] ?? 0) == 0) {
                                  setState(() => quotes.removeAt(i));
                                } else {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
