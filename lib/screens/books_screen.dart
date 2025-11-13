import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/book_card.dart'; // ✅ componente compartilhado


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
                  childAspectRatio: 0.46, // proporção ajustada das capas
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return BookCard(
                    bookId: book['id'] as int,
                    title: (book['title'] ?? '').toString(),
                    author: (book['author'] ?? '').toString(),
                    cover: (book['cover'] ?? '').toString(),
                    quotesCount: (book['quotes_count'] ?? 0) as int,
                  );
                },
              ),
            ),
    );
  }
}
