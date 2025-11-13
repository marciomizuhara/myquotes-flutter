import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/quote_card.dart';
import 'book_characters_screen.dart';
import '../utils/quotes_helper.dart';
import '../utils/quotes_cache_manager.dart'; // ✅ adicionado para cache

class BookQuotesScreen extends StatefulWidget {
  final int bookId;
  final String bookTitle;
  final String bookAuthor;
  final String? bookCover;

  const BookQuotesScreen({
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    this.bookCover,
    super.key,
  });

  @override
  State<BookQuotesScreen> createState() => _BookQuotesScreenState();
}

class _BookQuotesScreenState extends State<BookQuotesScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();
  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;

  static bool _hasLoadedOnce = false; // ✅ evita refetch
  late final String _bookCacheKey; // ✅ cache exclusivo por livro

  @override
  void initState() {
    super.initState();
    _bookCacheKey = 'book_cache_${widget.bookId}';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasLoadedOnce) {
        await _fetchQuotes();
        _hasLoadedOnce = true;
      } else {
        debugPrint('🧠 Reuso de cache — ${widget.bookTitle}');
        await _fetchQuotes();
      }
    });
  }

  Future<void> _fetchQuotes({String? term, bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    final cleanTerm = term?.trim();
    List<Map<String, dynamic>> data = [];

    final bool canUseCache =
        (!forceRefresh && (cleanTerm == null || cleanTerm.isEmpty));

    if (canUseCache) {
      final cached = await QuotesCacheManager.loadQuotes(_bookCacheKey);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('💾 Cache (${widget.bookTitle}) carregado (${cached.length} itens)');
        // 🔹 aplica filtro local por bookId
        data = List<Map<String, dynamic>>.from(
          cached.where((q) => q['book_id'] == widget.bookId),
        );
      } else {
        debugPrint('⚙️ Nenhum cache (${widget.bookTitle}), buscando Supabase...');
        data = await QuotesHelper.fetchQuotes(
          term: null,
          selectedType: selectedType,
          bookId: widget.bookId,
        );

        // 🔹 salva apenas citações deste livro
        final filteredData = data.where((q) => q['book_id'] == widget.bookId).toList();
        await QuotesCacheManager.saveQuotes(_bookCacheKey, filteredData);

        debugPrint('🧠 Cache criado com ${filteredData.length} citações');
      }
    }


    // 🎨 Filtro colorido aplicado localmente (sem refazer fetch)
    if (selectedType != null) {
      final before = data.length;
      data = data.where((q) => q['type'] == selectedType).toList();
      debugPrint('🎨 Filtro aplicado localmente → ${data.length}/$before mantidas');
    }

    setState(() {
      quotes = data;
      isLoading = false;
    });
  }

  // ------------------------------ UI --------------------------------------

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedType = active ? null : t;
        });
        await _fetchQuotes(term: searchCtrl.text);
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
      appBar: AppBar(
        title: Text(
          widget.bookTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt, color: Colors.white),
            tooltip: 'Ver personagens deste livro',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookCharactersScreen(
                    bookId: widget.bookId,
                    bookTitle: widget.bookTitle,
                    bookAuthor: widget.bookAuthor,
                    bookCover: widget.bookCover,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.bookCover ?? '',
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 110,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bookTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.bookAuthor,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${quotes.length} citações',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar citações neste livro...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () async {
                    searchCtrl.clear();
                    selectedType = null;
                    FocusScope.of(context).unfocus();
                    await _fetchQuotes();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _typeDot(1, red),
              _typeDot(2, yellow),
              _typeDot(3, green),
              _typeDot(4, blue),
              _typeDot(5, cyan),
              _typeDot(6, gray),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await QuotesCacheManager.clearCache(_bookCacheKey);
                      await _fetchQuotes(forceRefresh: true);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: quotes.length,
                      itemBuilder: (context, i) => QuoteCard(
                        quote: {
                          ...quotes[i],
                          'books': {
                            'title': widget.bookTitle,
                            'author': widget.bookAuthor,
                            'cover': widget.bookCover,
                          },
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
