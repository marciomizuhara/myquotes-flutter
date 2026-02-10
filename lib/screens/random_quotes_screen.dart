import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/quote_card/quote_card.dart';
import '../utils/quotes_helper.dart';

class RandomQuotesScreen extends StatefulWidget {
  const RandomQuotesScreen({Key? key}) : super(key: key);

  @override
  State<RandomQuotesScreen> createState() => _RandomQuotesScreenState();
}

class _RandomQuotesScreenState extends State<RandomQuotesScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    setState(() => isLoading = true);

    final data = await QuotesHelper.fetchQuotes(
      selectedType: selectedType, // ✅ aplica o filtro de cor
    );

    data.shuffle();

    setState(() {
      quotes = data;
      isLoading = false;
    });
  }

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = active ? null : t;
        });
        _fetchQuotes(); // ✅ refaz a busca com o tipo escolhido
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
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // 🔹 Search bar com espaçamento igual ao AllQuotes
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Gerar citações aleatórias...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _fetchQuotes,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                readOnly: true,
                onTap: _fetchQuotes,
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

            // 🔹 Lista de citações aleatórias
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchQuotes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: quotes.length,
                        itemBuilder: (context, i) => QuoteCard(quote: quotes[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
