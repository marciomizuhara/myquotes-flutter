import 'package:flutter/material.dart';
import '../utils/characters_helper.dart';
import '../widgets/character_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({Key? key}) : super(key: key);

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final supabase = Supabase.instance.client;
  final searchCtrl = TextEditingController();

  bool isLoading = true;
  String orderMode = 'random'; // random | desc | asc
  List<Map<String, dynamic>> characters = [];

  @override
  void initState() {
    super.initState();
    _fetchCharacters();
  }

  // 🔹 Busca geral e inicial
  Future<void> _fetchCharacters() async {
    setState(() => isLoading = true);

    final data = await CharactersHelper.fetchCharacters(orderMode: orderMode);
    setState(() {
      characters = data;
      isLoading = false;
    });
  }

  // 🔹 Nova busca filtrada (por termo)
  Future<void> _searchCharacters(String term) async {
    if (term.trim().isEmpty) {
      _fetchCharacters();
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = supabase
          .from('characters')
          .select('id, name, description, rating, tags, books(title, cover)');

      // Busca textual em name, description e tags
      final results = await query.or(
        'name.ilike.%$term%,description.ilike.%$term%,tags.ilike.%$term%',
      );

      setState(() {
        characters = List<Map<String, dynamic>>.from(results as List);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao pesquisar personagens: $e');
      setState(() => isLoading = false);
    }
  }

  void _setOrder(String mode) {
    if (orderMode == mode) return;
    setState(() => orderMode = mode);
    _fetchCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Characters',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward,
                color: orderMode == 'desc' ? Colors.amber : Colors.white),
            tooltip: 'Maior nota primeiro',
            onPressed: () => _setOrder('desc'),
          ),
          IconButton(
            icon: Icon(Icons.shuffle,
                color: orderMode == 'random' ? Colors.amber : Colors.white),
            tooltip: 'Aleatório',
            onPressed: () => _setOrder('random'),
          ),
          IconButton(
            icon: Icon(Icons.arrow_downward,
                color: orderMode == 'asc' ? Colors.amber : Colors.white),
            tooltip: 'Menor nota primeiro',
            onPressed: () => _setOrder('asc'),
          ),
        ],
      ),

      // 🔹 Corpo
      body: Column(
        children: [
          // Barra de pesquisa (idêntica à do AllQuotesScreen)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar personagens...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                    _fetchCharacters();
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
              onSubmitted: (term) => _searchCharacters(term),
            ),
          ),

          // Lista de personagens
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : RefreshIndicator(
                    onRefresh: _fetchCharacters,
                    color: Colors.amber,
                    backgroundColor: Colors.black,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      itemCount: characters.length,
                      itemBuilder: (context, i) =>
                          CharacterCard(character: characters[i], showBook: true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
