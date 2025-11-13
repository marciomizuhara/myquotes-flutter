import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card.dart';
import '../widgets/type_selector.dart'; // ✅ seletor modularizado
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
  static const _favoritesCacheKey = 'favorites_cache_v1';
  static bool _hasLoadedOnce = false; // 🔹 evita sobrescrever cache

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasLoadedOnce) {
        await _fetchFavorites();
        _hasLoadedOnce = true;
      } else {
        debugPrint('💛 Reuso de cache — não recarregando do Supabase');
        await _fetchFavorites();
      }
    });
  }

  Future<void> _fetchFavorites({String? term, bool forceRefresh = false}) async {
    setState(() => isLoading = true);
    final cleanTerm = term?.trim();
    debugPrint('💛 Modo atual: $_sortMode | Termo: "$cleanTerm"');

    List<Map<String, dynamic>> data = [];
    bool fetchedFromSupabase = false;

    // ✅ 1. Usa cache existente se possível
    final bool canUseCache =
        (_sortMode == 'random' && !forceRefresh && (cleanTerm == null || cleanTerm.isEmpty));

    if (canUseCache) {
      final cached = await QuotesCacheManager.loadQuotes(_favoritesCacheKey);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('💾 Cache (favoritos) carregado (${cached.length} itens)');
        data = List<Map<String, dynamic>>.from(cached)..shuffle();
      } else {
        debugPrint('⚙️ Nenhum cache de favoritos, buscando do Supabase...');
        data = await _fetchFromSupabase();
        fetchedFromSupabase = true;
      }
    } else if (cleanTerm != null && cleanTerm.isNotEmpty) {
      debugPrint('🔍 Busca com operadores AND/OR ativa');
      data = await _fetchSearchFavorites(cleanTerm);
    } else {
      debugPrint('⚙️ Fallback: carregando todos os favoritos do Supabase');
      data = await _fetchFromSupabase();
      fetchedFromSupabase = true;
    }

    // 🎨 Filtro colorido local
    if (selectedType != null) {
      final before = data.length;
      data = data.where((q) {
        final t = q['type'];
        final intType = int.tryParse(t?.toString() ?? '');
        return intType == selectedType;
      }).toList();
      debugPrint('🎨 Filtro de tipo aplicado → ${data.length}/$before mantidas');
    }

    // ✅ 2. Salva cache só se veio do Supabase
    if (fetchedFromSupabase && data.isNotEmpty) {
      await QuotesCacheManager.saveQuotes(_favoritesCacheKey, data);
      debugPrint('📦 Cache atualizado (${data.length} favoritos totais)');
    }

    setState(() {
      quotes = data;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFromSupabase() async {
    final res = await supabase
        .from('quotes')
        .select(
          'id, text, page, type, notes, is_favorite::int, book_id, books(title, author, cover)',
        )
        .eq('is_favorite', 1)
        .order('id', ascending: true)
        .limit(2000); // 🔹 força retorno amplo

    final data =
        (res as List).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

    debugPrint('💛 FetchFromSupabase retornou ${data.length} favoritos');
    return data;
  }

  Future<List<Map<String, dynamic>>> _fetchSearchFavorites(String term) async {
    final Map<int, Map<String, dynamic>> allResults = {};
    final orParts = term.split(' OR ');

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

    final results = allResults.values
        .where((q) =>
            q['is_favorite'] == 1 ||
            q['is_favorite'] == true ||
            q['is_favorite'] == '1' ||
            (q['is_favorite'] is String && q['is_favorite'].toLowerCase() == 'true'))
        .toList();

    debugPrint('💛 FetchFavorites (RPC) → ${results.length} favoritas encontradas');
    return results;
  }

  void _changeSortMode(String mode) async {
    setState(() => _sortMode = mode);
    await _fetchFavorites(term: searchCtrl.text.isEmpty ? null : searchCtrl.text);
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
      onTap: () async {
        setState(() {
          selectedType = active ? null : t;
        });
        await _fetchFavorites(term: searchCtrl.text);
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
                  hintText: '',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () async {
                      searchCtrl.clear();
                      selectedType = null;
                      FocusScope.of(context).unfocus();
                      await _fetchFavorites();
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
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Recarregar do Supabase',
                    onPressed: () async {
                      await QuotesCacheManager.clearCache(_favoritesCacheKey);
                      await _fetchFavorites(forceRefresh: true);
                    },
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
                  : RefreshIndicator(
                      onRefresh: () async {
                        await QuotesCacheManager.clearCache(_favoritesCacheKey);
                        await _fetchFavorites(forceRefresh: true);
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
                                  _favoritesCacheKey, quotes);
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
