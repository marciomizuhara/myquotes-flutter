import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/quote_card.dart';
import 'book_characters_screen.dart';
import '../utils/quotes_cache_manager.dart';
import '../utils/quotes_search_manager.dart';
import '../widgets/cached_cover_image.dart';

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
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;

  late final String _bookCacheKey;
  static bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();

    _bookCacheKey = 'book_quotes_cache_${widget.bookId}';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runSearch();
      _hasLoadedOnce = true;
    });
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    quotes = await QuotesSearchManager.search(
      origin: 'book',
      rawTerm: searchCtrl.text,
      typeFilter: selectedType,
      sortMode: 'none',
      bookId: widget.bookId,
      cacheKey: _bookCacheKey,
      forceRefresh: forceRefresh,
    );

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
          // 📘 Cabeçalho do livro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CachedCoverImage(
                  url: widget.bookCover ?? '',
                  width: 80,
                  height: 110,
                  borderRadius: BorderRadius.circular(10),
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

          // 🔍 Campo de busca
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

          // 🎨 Bolinhas
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

          // 📜 Lista de citações
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await QuotesCacheManager.clearCache(_bookCacheKey);
                      await _runSearch(forceRefresh: true);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: quotes.length,
                      itemBuilder: (context, i) {
                        final q = quotes[i];

                        return QuoteCard(
                          quote: {
                            ...q,
                            'books': {
                              'title': widget.bookTitle,
                              'author': widget.bookAuthor,
                              'cover': widget.bookCover,
                            },
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
