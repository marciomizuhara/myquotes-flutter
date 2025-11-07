import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class QuotesHelper {
  static final supabase = Supabase.instance.client;
  static String currentSortMode = 'random';

  // 🔹 Busca principal de citações (com suporte a "OR")
  static Future<List<Map<String, dynamic>>> fetchQuotes({
    String? term,
    int? selectedType,
    int? bookId,
  }) async {
    try {
      List<dynamic> data = [];

      if (term != null && term.trim().isNotEmpty) {
        final rawTerm = term.trim();

        // 🧠 Lógica combinada de AND / OR
        if (rawTerm.contains(' OR ') || rawTerm.contains(' AND ')) {
          final orParts = rawTerm.split(' OR ');
          final Map<int, Map<String, dynamic>> allResults = {};

          for (var orSegment in orParts) {
            // cada segmento pode ter AND dentro dele
            final andParts = orSegment.split(' AND ');
            List<Map<String, dynamic>>? andResult;

            for (var raw in andParts) {
              final clean = raw.replaceAll('"', '').trim();
              if (clean.isEmpty) continue;

              final res = await supabase.rpc('search_quotes', params: {
                'search_term': clean,
              });

              final List<Map<String, dynamic>> current =
                  (res as List).map((e) => Map<String, dynamic>.from(e)).toList();

              // 🔹 se é o primeiro termo do AND, inicia
              if (andResult == null) {
                andResult = current;
              } else {
                // 🔹 interseção (mantém apenas IDs que aparecem em ambos)
                final ids = andResult.map((q) => q['id']).toSet();
                andResult = current.where((q) => ids.contains(q['id'])).toList();
              }
            }

            // adiciona resultado do segmento (após aplicar AND)
            if (andResult != null) {
              for (final q in andResult) {
                final id = int.tryParse(q['id'].toString()) ?? 0;
                if (id > 0) allResults[id] = q;
              }
            }
          }

          data = allResults.values.toList();
          print('🔎 Busca combinada OR/AND → ${data.length} resultados totais');
        } else {
          // 🔹 busca normal (sem operadores)
          final res = await supabase.rpc('search_quotes', params: {
            'search_term': rawTerm,
          });
          data = (res as List);
        }

        // 🔹 Filtro opcional por livro
        if (bookId != null) {
          data = data
              .where((q) =>
                  q['book_id'] != null &&
                  int.tryParse(q['book_id'].toString()) == bookId)
              .toList();
          print(
              '🔍 Filtro pós-RPC aplicado → ${data.length} citações correspondem ao book_id=$bookId');
        }
      } else {
        // 🔸 Busca geral sem termo
        List<int>? filteredIds;
        if (bookId != null) {
          final idsRes = await supabase
              .from('quotes')
              .select('id')
              .eq('book_id', bookId);

          filteredIds = (idsRes as List)
              .map<int>((e) => int.tryParse(e['id'].toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }

        var query = supabase.from('quotes').select(
              'id, text, page, type, notes, is_favorite, book_id, books(title, author, cover)',
            );

        if (filteredIds != null && filteredIds.isNotEmpty) {
          query = query.inFilter('id', filteredIds);
        }

        query.order('id', ascending: true);
        query.limit(bookId != null ? 2000 : 10000);

        final res = await query;
        data = (res as List);

        if (currentSortMode == 'newest') {
          data = data.reversed.toList();
        } else if (currentSortMode == 'random') {
          data.shuffle(Random());
        }
      }

      print('🟨 FetchQuotes → Total recebidos: ${data.length}');
      for (var q in data.take(8)) {
        print('🟡 Quote ${q['id']} → book_id=${q['book_id']}');
      }

      // 🔹 Normalização dos campos
      var normalized = data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e);
        final bookData = q['books'];
        final books = (bookData is Map<String, dynamic>)
            ? bookData
            : {
                'title': q['book_title'] ?? '',
                'author': q['book_author'] ?? '',
                'cover': q['book_cover'] ?? '',
              };

        final favValue = q['is_favorite'];
        final favInt = (favValue == 1 ||
                favValue == true ||
                favValue == '1' ||
                (favValue is String && favValue.toLowerCase() == 'true'))
            ? 1
            : 0;

        final typeVal = q['type'];
        final intType = int.tryParse(typeVal?.toString() ?? '');

        return {
          'id': int.tryParse(q['id'].toString()) ?? 0,
          'page': q['page'],
          'type': intType ?? q['type'],
          'text': q['text'] ?? '',
          'notes': q['notes'],
          'book_id': q['book_id'],
          'is_favorite': favInt,
          'books': books,
        };
      }).toList();

      // 🔹 Filtro de tipo (color dot)
      if (selectedType != null) {
        normalized = normalized.where((q) {
          final rawType = q['type'];
          final intType = int.tryParse(rawType?.toString() ?? '');
          return intType == selectedType;
        }).toList();
      }

      final favCount =
          normalized.where((q) => q['is_favorite'] == 1).length;
      print('💛 FetchQuotes → Favoritas identificadas: $favCount de ${normalized.length} totais');

      return normalized;
    } catch (e) {
      print('❌ Erro ao buscar citações: $e');
      return [];
    }
  }


  // 🔹 Buscar lista de autores e contagem de livros
  static Future<List<Map<String, dynamic>>> fetchWriters() async {
    try {
      final res = await supabase
          .from('books')
          .select('author')
          .order('author', ascending: true);

      final Map<String, int> countMap = {};
      for (final b in res) {
        final author = (b['author'] ?? 'Autor desconhecido').toString();
        countMap[author] = (countMap[author] ?? 0) + 1;
      }

      final data = countMap.entries
          .map((e) => {
                'author': e.key,
                'book_count': e.value,
              })
          .toList()
        ..sort((a, b) => a['author']
            .toString()
            .toLowerCase()
            .compareTo(b['author'].toString().toLowerCase()));

      print('📚 fetchWriters → ${data.length} autores carregados');
      return data;
    } catch (e) {
      print('❌ Erro ao buscar autores: $e');
      return [];
    }
  }

  // 🔹 Buscar livros de um autor específico
  static Future<List<Map<String, dynamic>>> fetchBooksByAuthor(String author) async {
    try {
      final res = await supabase
          .from('books')
          .select('id, title, author, cover')
          .eq('author', author)
          .order('title', ascending: true);

      final data = (res as List)
          .map<Map<String, dynamic>>((b) => {
                'id': int.tryParse(b['id'].toString()) ?? 0,
                'title': b['title'] ?? '',
                'author': b['author'] ?? '',
                'cover': b['cover'] ?? '',
              })
          .toList();

      print('📖 fetchBooksByAuthor("$author") → ${data.length} livros encontrados');
      return data;
    } catch (e) {
      print('❌ Erro ao buscar livros do autor "$author": $e');
      return [];
    }
  }
}
