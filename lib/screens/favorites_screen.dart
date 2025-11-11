import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card.dart';
import '../utils/quotes_cache_manager.dart';

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
    const cacheKey = 'favorites_cache_v1';

    try {
      List<Map<String, dynamic>> data = [];

      // ✅ 1. Cache — só se não houver termo de busca
      if (term == null || term.trim().isEmpty) {
        final cached = await QuotesCacheManager.loadQuotes(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          debugPrint('💾 Cache de favoritos carregado (${cached.length})');
          data = List<Map<String, dynamic>>.from(cached)..shuffle();
        }
      }

      // ✅ 2. Busca com termo (com suporte a AND / OR)
      if (data.isEmpty && term != null && term.trim().isNotEmpty) {
        final rawTerm = term.trim();
        final Map<int, Map<String, dynamic>> allResults = {};

        if (rawTerm.contains(' OR ') || rawTerm.contains(' AND ')) {
          final orParts = rawTerm.split(' OR ');

          for (var orSegment in orParts) {
            final andParts = orSegment.split(' AND ');
            List<Map<String, dynamic>>? andResult;

            for (var raw in andParts) {
              final clean = raw.replaceAll('"', '').trim();
              if (clean.isEmpty) continue;

              final res = await supabase.rpc('search_quotes', params: {'search_term': clean});
              final current = (res as List)
                  .map<Map<String, dynamic>>((e) {
                    final q = Map<String, dynamic>.from(e);
                    q['books'] = {
                      'title': q['book_title'] ?? '',
                      'author': q['book_author'] ?? '',
                      'cover': q['book_cover'] ?? '',
                    };
                    return q;
                  })
                  .toList();

              if (andResult == null) {
                andResult = current;
              } else {
                final ids = andResult.map((q) => q['id']).toSet();
                andResult = current.where((q) => ids.contains(q['id'])).toList();
              }
            }

            if (andResult != null) {
              for (final q in andResult) {
                final id = int.tryParse(q['id'].toString()) ?? 0;
                if (id > 0) allResults[id] = q;
              }
            }
          }

          data = allResults.values.toList();
          debugPrint('🔍 Busca combinada OR/AND → ${data.length} resultados totais');
        } else {
          final res = await supabase.rpc('search_quotes', params: {'search_term': rawTerm});
          data = (res as List)
              .map<Map<String, dynamic>>((e) {
                final q = Map<String, dynamic>.from(e);
                q['books'] = {
                  'title': q['book_title'] ?? '',
                  'author': q['book_author'] ?? '',
                  'cover': q['book_cover'] ?? '',
                };
                return q;
              })
              .toList();
        }

        // 🔹 Filtra apenas favoritas
        data = data
            .where((q) =>
                q['is_favorite'] == 1 ||
                q['is_favorite'] == true ||
                q['is_favorite'] == '1' ||
                (q['is_favorite'] is String &&
                    q['is_favorite'].toLowerCase() == 'true'))
            .toList();

        debugPrint('💛 FetchFavorites (RPC) → ${data.length} favoritas encontradas');
      }

      // ✅ 3. Busca direta no Supabase (sem termo, fallback)
      if (data.isEmpty && (term == null || term.trim().isEmpty)) {
        final query = supabase
            .from('quotes')
            .select(
              'id, text, page, type, notes, is_favorite::int, book_id, books(title, author, cover)',
            )
            .eq('is_favorite', 1)
            .order('id', ascending: true);

        final res = await query;
        data = (res as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        debugPrint('💛 FetchFavorites (Supabase direto) → ${data.length}');
      }

      // ✅ 4. Ordenação local
      if (_sortMode == 'newest') {
        data.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      } else if (_sortMode == 'oldest') {
        data.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      } else if (_sortMode == 'random') {
        data.shuffle();
      }

      // 🎨 5. Aplica filtro colorido (tipo) localmente
      if (selectedType != null) {
        final before = data.length;
        data = data.where((q) => q['type'] == selectedType).toList();
        debugPrint('🎨 Filtro de tipo aplicado localmente → ${data.length}/$before mantidas');
      }

      // ✅ 6. Atualiza cache (somente se sem termo)
      if ((term == null || term.trim().isEmpty) && data.isNotEmpty) {
        await QuotesCacheManager.saveQuotes(cacheKey, data);
        debugPrint('📦 Cache de favoritos salvo (${data.length})');
      }

      // ✅ 7. Atualiza UI
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

  void _copyQuote(Map<String, dynamic> q) {
    final text = q['text'] ?? '';
    final author = q['books']?['author'] ?? 'Autor desconhecido';
    final title = q['books']?['title'] ?? 'Livro não informado';
    final formatted = '$text\n\n$author - $title';
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
                  _typeDot(6, gray),
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
                            itemBuilder: (context, i) {
                              final q = quotes[i];
                              return GestureDetector(
                                onDoubleTap: () => _copyQuote(q),
                                child: QuoteCard(
                                  quote: q,
                                  onFavoriteChanged: () async {
                                    if ((quotes[i]['is_favorite'] ?? 0) == 0) {
                                      setState(() => quotes.removeAt(i));
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                ),
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
