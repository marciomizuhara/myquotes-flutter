import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/quotes_helper.dart';
import '../widgets/book_card.dart'; // ✅ componente compartilhado

class WritersBooksScreen extends StatefulWidget {
  final String author;
  const WritersBooksScreen({required this.author, Key? key}) : super(key: key);

  @override
  State<WritersBooksScreen> createState() => _WritersBooksScreenState();
}

class _WritersBooksScreenState extends State<WritersBooksScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> books = [];

  @override
  void initState() {
    super.initState();
    _fetchBooksByAuthor();
  }

  Future<void> _fetchBooksByAuthor() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('books')
          .select('id, title, author, cover, quotes(id)')
          .eq('author', widget.author)
          .order('title', ascending: true);

      final data = List<Map<String, dynamic>>.from(response as List);

      for (final b in data) {
        final quotesList = b['quotes'] as List<dynamic>? ?? [];
        b['quotes_count'] = quotesList.length;
      }

      setState(() {
        books = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar livros do autor ${widget.author}: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          widget.author,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : books.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum livro encontrado para este autor.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBooksByAuthor,
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
                        quotesCount: (book['quotes_count'] ?? 0) as int,
                      );
                    },
                  ),
                ),
    );
  }
}
