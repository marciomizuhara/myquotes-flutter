import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/quote_card.dart';
import '../utils/quotes_helper.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({Key? key}) : super(key: key);

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> quotes = [];
  int? selectedType;
  String _sortMode = 'random'; // ✅ modo padrão ao abrir

  @override
  void initState() {
    super.initState();
    _fetchQuotes(); // já usa random por padrão
  }

  Future<void> _fetchQuotes({String? term}) async {
    setState(() => isLoading = true);

    QuotesHelper.currentSortMode = _sortMode;

    final data = await QuotesHelper.fetchQuotes(
      term: term,
      selectedType: selectedType,
    );

    // 🔹 Garante que todas as quotes venham com is_favorite coerente (int)
    final normalized = data.map((q) {
      q['is_favorite'] = (q['is_favorite'] ?? 0) == 1 ? 1 : 0;
      return q;
    }).toList();

    setState(() {
      quotes = normalized;
      isLoading = false;
    });
  }

  void _changeSortMode(String mode) {
    setState(() => _sortMode = mode);
    _fetchQuotes(term: searchCtrl.text.isEmpty ? null : searchCtrl.text);
  }

  Widget _typeDot(int t, Color fill) {
    final bool active = selectedType == t;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = active ? null : t;
        });
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
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Pesquisar citações...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      searchCtrl.clear();
                      selectedType = null;
                      FocusScope.of(context).unfocus();
                      _fetchQuotes();
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                ),
                onSubmitted: (term) => _fetchQuotes(term: term),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _typeDot(1, red),
                  _typeDot(2, yellow),
                  _typeDot(3, green),
                  _typeDot(4, blue),
                  _typeDot(5, cyan),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                    tooltip: 'Mais antigas',
                    onPressed: () => _changeSortMode('oldest'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    tooltip: 'Aleatórias',
                    onPressed: () => _changeSortMode('random'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    tooltip: 'Mais recentes',
                    onPressed: () => _changeSortMode('newest'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _fetchQuotes(
                        term: searchCtrl.text.isEmpty ? null : searchCtrl.text,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: quotes.length,
                        itemBuilder: (context, i) => QuoteCard(
                          quote: quotes[i],
                          onFavoriteChanged: () {
                            // 🔹 Atualiza apenas o item alterado
                            setState(() {
                              quotes[i]['is_favorite'] =
                                  quotes[i]['is_favorite'] == 1 ? 0 : 1;
                            });
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
