import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../widgets/quote_card.dart';
import '../utils/quotes_helper.dart';
import '../utils/quotes_cache_manager.dart'; // ✅ cache global único

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({Key? key}) : super(key: key);

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;
  String _sortMode = 'random'; // modo padrão
  static const _globalCacheKey = 'quotes_global_cache_v1'; // 🔹 cache único
  static bool _hasLoadedOnce = false; // ✅ controla se já foi carregado nesta sessão

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ⚙️ Só limpa manualmente quando for necessário resetar (comente depois)
      // await QuotesCacheManager.clearCache(_globalCacheKey);
      // debugPrint('🧹 Cache global limpo manualmente');

      if (!_hasLoadedOnce) {
        _fetchQuotes();
        _hasLoadedOnce = true;
      } else {
        debugPrint('🧠 Reuso de cache — não recarregando do Supabase');
        _fetchQuotes();
      }
    });
  }



  Future<void> _fetchQuotes({String? term, bool forceRefresh = false}) async {
    setState(() => isLoading = true);
    QuotesHelper.currentSortMode = _sortMode;
    final cleanTerm = term?.trim();
    debugPrint('🔁 Modo atual: $_sortMode | Termo: "$cleanTerm"');

    List<Map<String, dynamic>> data = [];

    final bool canUseCache =
        (_sortMode == 'random' && !forceRefresh && (cleanTerm == null || cleanTerm.isEmpty));

    if (canUseCache) {
      final cached = await QuotesCacheManager.loadQuotes(_globalCacheKey);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('💾 Cache (random) carregado (${cached.length} itens)');
        data = List<Map<String, dynamic>>.from(cached)..shuffle();
      } else {
        debugPrint('⚙️ Nenhum cache (random), buscando Supabase...');
        data = await QuotesHelper.fetchQuotes(
          term: null,
          selectedType: selectedType,
          sortMode: 'random',
        );
        await QuotesCacheManager.saveQuotes(_globalCacheKey, data);
        debugPrint('🧠 Cache inicial criado com ${data.length} citações totais');
      }
    } else if (_sortMode == 'one_per_book_asc' || _sortMode == 'one_per_book_desc') {
      debugPrint('🔄 Modo $_sortMode → Supabase direto (sem cache)');
      data = await QuotesHelper.fetchQuotes(
        term: cleanTerm,
        selectedType: selectedType,
        sortMode: _sortMode,
      );
    } else if (cleanTerm != null && cleanTerm.isNotEmpty) {
      debugPrint('🔍 Executando busca com operadores (AND/OR habilitados)');
      data = await QuotesHelper.fetchQuotes(
        term: cleanTerm,
        selectedType: selectedType,
        sortMode: _sortMode,
      );
    } else {
      debugPrint('⚙️ Fallback: modo $_sortMode sem termo');
      data = await QuotesHelper.fetchQuotes(
        term: null,
        selectedType: selectedType,
        sortMode: _sortMode,
      );
    }

    // 🎨 Filtro colorido — aplicado localmente SEM refazer fetch
    if (selectedType != null) {
      final before = data.length;
      data = data.where((q) => q['type'] == selectedType).toList();
      debugPrint('🎨 Filtro de tipo aplicado localmente → ${data.length}/$before mantidas');
    }

    // 🔹 Atualiza interface
    setState(() {
      quotes = data;
      isLoading = false;
    });
  }



  void _changeSortMode(String mode) async {
    setState(() => _sortMode = mode);
    _fetchQuotes(term: searchCtrl.text.isEmpty ? null : searchCtrl.text);
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
        _fetchQuotes(term: searchCtrl.text);
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
                  hintText: 'Pesquisar citações (use AND / OR)...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () async {
                      searchCtrl.clear();
                      selectedType = null;
                      FocusScope.of(context).unfocus();
                      _fetchQuotes();
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
                onSubmitted: (term) => _fetchQuotes(term: term),
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
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    tooltip: 'Newest',
                    onPressed: () => _changeSortMode('one_per_book_desc'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    tooltip: 'Shuffle',
                    onPressed: () => _changeSortMode('random'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                    tooltip: 'Oldest',
                    onPressed: () => _changeSortMode('one_per_book_asc'),
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
                        await QuotesCacheManager.clearCache(_globalCacheKey);
                        await _fetchQuotes(forceRefresh: true);
                      },
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
                                setState(() {
                                  quotes[i]['is_favorite'] =
                                      quotes[i]['is_favorite'] == 1 ? 0 : 1;
                                });
                                await QuotesCacheManager.saveQuotes(
                                    _globalCacheKey, quotes);
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
