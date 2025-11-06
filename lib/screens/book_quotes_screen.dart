import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/quote_card.dart';
import 'book_characters_screen.dart';
import '../utils/quotes_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  Future<void> _fetchQuotes({String? term}) async {
    setState(() => isLoading = true);

    // ✅ Mantém sempre o bookId para evitar que traga todas as citações
    final data = await QuotesHelper.fetchQuotes(
      term: term,
      selectedType: selectedType,
      bookId: widget.bookId,
    );

    setState(() {
      quotes = data;
      isLoading = false;
    });
  }

  // ------------------------------ UI --------------------------------------

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = active ? null : t;
        });

        // ✅ Mantém o filtro de livro ao trocar o tipo
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

      // 🔹 Corpo da tela
      body: Column(
        children: [
          // 🔹 Cabeçalho com capa, título, autor e total de citações
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Capa
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

                // Informações do livro
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

          // 🔹 Barra de pesquisa
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
                  onPressed: () {
                    searchCtrl.clear();
                    selectedType = null;
                    FocusScope.of(context).unfocus();

                    // ✅ Garante que o bookId seja preservado ao limpar busca
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
              // ✅ Mantém bookId também na busca
              onSubmitted: (term) => _fetchQuotes(term: term),
            ),
          ),

          // 🔹 Filtros coloridos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _typeDot(1, red),
              _typeDot(2, yellow),
              _typeDot(3, green),
              _typeDot(4, blue),
              _typeDot(5, cyan),
            ],
          ),
          const SizedBox(height: 6),

          // 🔹 Lista de citações
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    // ✅ Passa o bookId para o refresh também
                    onRefresh: () => _fetchQuotes(term: searchCtrl.text),
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
