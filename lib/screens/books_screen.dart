import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/book_card.dart';
import '../utils/books_cache_manager.dart';
import '../utils/books_search_manager.dart';

enum SortMode { asc, desc, shuffle }

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final supabase = Supabase.instance.client;

  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> books = [];

  SortMode sortMode = SortMode.shuffle;
  String sortModeString = 'shuffle';

  @override
  void initState() {
    super.initState();
    _runSearchBooks();
  }

  Future<void> _runSearchBooks({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    books = await BooksSearchManager.search(
      rawTerm: searchCtrl.text,
      sortMode: sortModeString,
      cacheKey: 'books_cache_v1',
      forceRefresh: forceRefresh,
    );

    setState(() => isLoading = false);
  }

  void _setSort(SortMode mode) {
    setState(() {
      sortMode = mode;

      if (mode == SortMode.asc) sortModeString = 'asc';
      if (mode == SortMode.desc) sortModeString = 'desc';
      if (mode == SortMode.shuffle) sortModeString = 'shuffle';
    });

    _runSearchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // ------------------------------------------------------------
            // 🔍 Search bar — igual QuotesScreen
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search title or author...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () async {
                      searchCtrl.clear();
                      FocusScope.of(context).unfocus();
                      await _runSearchBooks();
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _runSearchBooks(),
              ),
            ),

            // ------------------------------------------------------------
            // 🔽 Barra de ações — igual QuotesScreen (refresh, shuffle, asc)
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Refresh from Supabase',
                    onPressed: () async {
                      await BooksCacheManager.clear();
                      await _runSearchBooks(forceRefresh: true);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    tooltip: "ASC",
                    onPressed: () => _setSort(SortMode.asc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    tooltip: "Shuffle",
                    onPressed: () => _setSort(SortMode.shuffle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                    tooltip: "DESC",
                    onPressed: () => _setSort(SortMode.desc),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 6),

            // ------------------------------------------------------------
            // 📚 Grid de livros (mantido igual)
            // ------------------------------------------------------------
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await BooksCacheManager.clear();
                        await _runSearchBooks(forceRefresh: true);
                      },
                      color: Colors.amber,
                      backgroundColor: Colors.black,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.46,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return BookCard(
                            bookId: book['id'] as int,
                            title: (book['title'] ?? '').toString(),
                            author: (book['author'] ?? '').toString(),
                            cover: (book['cover'] ?? '').toString(),
                            quotesCount:
                                (book['quotes_count'] ?? 0) as int,
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
