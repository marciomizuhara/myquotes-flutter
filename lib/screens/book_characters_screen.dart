import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/characters_helper.dart';
import '../widgets/character_card.dart';
import '../widgets/cached_cover_image.dart';

class BookCharactersScreen extends StatefulWidget {
  final int bookId;
  final String bookTitle;
  final String? bookAuthor;
  final String? bookCover;

  const BookCharactersScreen({
    required this.bookId,
    required this.bookTitle,
    this.bookAuthor,
    this.bookCover,
    Key? key,
  }) : super(key: key);

  @override
  State<BookCharactersScreen> createState() => _BookCharactersScreenState();
}

class _BookCharactersScreenState extends State<BookCharactersScreen> {
  bool isLoading = true;
  String orderMode = 'desc'; // padrão: maior nota primeiro
  List<Map<String, dynamic>> characters = [];

  @override
  void initState() {
    super.initState();
    _fetchCharacters();
  }

  Future<void> _fetchCharacters() async {
    setState(() => isLoading = true);

    final data = await CharactersHelper.fetchCharacters(
      orderMode: orderMode,
      bookId: widget.bookId,
    );

    setState(() {
      characters = data;
      isLoading = false;
    });
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
        title: Text(
          widget.bookTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_upward,
              color: orderMode == 'desc' ? Colors.amber : Colors.white,
            ),
            tooltip: 'Maior nota primeiro',
            onPressed: () => _setOrder('desc'),
          ),
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: orderMode == 'random' ? Colors.amber : Colors.white,
            ),
            tooltip: 'Aleatório',
            onPressed: () => _setOrder('random'),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_downward,
              color: orderMode == 'asc' ? Colors.amber : Colors.white,
            ),
            tooltip: 'Menor nota primeiro',
            onPressed: () => _setOrder('asc'),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                // 🔹 Cabeçalho igual ao da BookQuotesScreen
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Capa do livro (agora com cache)
                      CachedCoverImage(
                        url: widget.bookCover ?? '',
                        width: 80,
                        height: 110,
                        borderRadius: BorderRadius.circular(10),
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
                            if (widget.bookAuthor != null)
                              Text(
                                widget.bookAuthor!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              '${characters.length} personagens',
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

                const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Characters',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),

                // 🔹 Lista de personagens
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchCharacters,
                    color: Colors.amber,
                    backgroundColor: Colors.black,
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      itemCount: characters.length,
                      itemBuilder: (context, i) => CharacterCard(
                        character: characters[i],
                        showBook: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
