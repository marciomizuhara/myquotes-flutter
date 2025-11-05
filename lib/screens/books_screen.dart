import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_quotes_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> books = [];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('books')
          .select('id, title, author, cover, quotes(id)')
          .order('title', ascending: true);

      final data = List<Map<String, dynamic>>.from(response as List);

      // 🔹 Mapeia total de citações por livro
      for (final b in data) {
        final quotesList = b['quotes'] as List<dynamic>? ?? [];
        b['quotes_count'] = quotesList.length;
      }

      setState(() {
        books = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar livros: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Books',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : RefreshIndicator(
              onRefresh: _fetchBooks,
              color: Colors.amber,
              backgroundColor: Colors.black,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 🔹 3 livros por linha
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.58, // proporção ajustada das capas
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final cover = (book['cover'] ?? '').toString();
                  final title = (book['title'] ?? '').toString();
                  final author = (book['author'] ?? '').toString();
                  final quotesCount = (book['quotes_count'] ?? 0) as int;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookQuotesScreen(
                            bookId: book['id'] as int,
                            bookTitle: title,
                            bookAuthor: author,
                            bookCover: cover,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Capa do livro
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              cover,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.black26,
                                child: const Icon(Icons.broken_image, color: Colors.white38, size: 28),
                              ),
                            ),
                          ),

                          // Informações
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$quotesCount citações',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
