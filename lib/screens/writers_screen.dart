import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/quotes_helper.dart';
import '../utils/colors.dart';
import 'writers_books_screen.dart';

class WritersScreen extends StatefulWidget {
  const WritersScreen({Key? key}) : super(key: key);

  @override
  State<WritersScreen> createState() => _WritersScreenState();
}

class _WritersScreenState extends State<WritersScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> writers = [];

  @override
  void initState() {
    super.initState();
    _fetchWriters();
  }

  Future<void> _fetchWriters({String? term}) async {
    setState(() => isLoading = true);

    // 🔹 busca todos os autores
    var data = await QuotesHelper.fetchWriters();

    // 🔹 aplica filtro de busca local, se houver termo
    if (term != null && term.trim().isNotEmpty) {
      final t = term.trim().toLowerCase();
      data = data
          .where((w) => (w['author'] ?? '')
              .toString()
              .toLowerCase()
              .contains(t))
          .toList();
    }

    setState(() {
      writers = data;
      isLoading = false;
    });
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
            // 🔹 Campo de pesquisa
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Pesquisar autor...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      searchCtrl.clear();
                      FocusScope.of(context).unfocus();
                      _fetchWriters();
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
                onSubmitted: (term) => _fetchWriters(term: term),
              ),
            ),

            const SizedBox(height: 4),

            // 🔹 Lista de autores
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _fetchWriters(
                          term: searchCtrl.text.isEmpty
                              ? null
                              : searchCtrl.text),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        itemCount: writers.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Colors.white10,
                          height: 1,
                          thickness: 0.3,
                        ),
                        itemBuilder: (context, i) {
                          final w = writers[i];
                          final name = (w['author'] ?? '').toString();
                          final count =
                              (w['book_count'] ?? 0).toString(); // 🔹 campo ajustado

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WritersBooksScreen(author: name),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    count == "1"
                                        ? "1 livro"
                                        : "$count livros",
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }
}
