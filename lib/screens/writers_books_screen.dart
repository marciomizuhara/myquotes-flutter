import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/quotes_helper.dart';
import '../utils/colors.dart';
import 'book_quotes_screen.dart';

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
    final data = await QuotesHelper.fetchBooksByAuthor(widget.author);
    setState(() {
      books = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true, // 🔹 centraliza o nome do autor
        title: Text(
          widget.author,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : books.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum livro encontrado para este autor.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchBooksByAuthor,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.58, // ajusta a altura proporcional
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, i) {
                        final b = books[i];
                        final cover = (b['cover'] ?? '').toString();
                        final title = (b['title'] ?? '').toString();
                        final author = (b['author'] ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookQuotesScreen(
                                  bookId: b['id'],
                                  bookTitle: title,
                                  bookAuthor: author,
                                  bookCover: cover,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🔹 Capa
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: cover.isNotEmpty
                                        ? Image.network(
                                            cover,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, _, __) =>
                                                Container(
                                              color: Colors.black26,
                                              child: const Icon(
                                                Icons.book,
                                                color: Colors.white30,
                                                size: 48,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.black26,
                                            child: const Icon(
                                              Icons.book,
                                              color: Colors.white30,
                                              size: 48,
                                            ),
                                          ),
                                  ),
                                ),

                                // 🔹 Título
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                ),

                                // 🔹 Autor
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    author,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
