import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class QuotesHelper {
  static final supabase = Supabase.instance.client;
  static String currentSortMode = 'random';

  static Future<List<Map<String, dynamic>>> fetchQuotes({
    String? term,
    int? selectedType,
    int? bookId,
  }) async {
    try {
      List<dynamic> data;

      if (term != null && term.trim().isNotEmpty) {
        // 🔹 Busca via RPC (sem filtro de livro)
        final res = await supabase.rpc('search_quotes', params: {
          'search_term': term.trim(),
        });
        data = (res as List);

        // 🔹 Se bookId for informado, filtra os resultados localmente
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
        // 🔹 Se bookId for informado, buscar apenas as IDs do livro primeiro
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

        // 🔹 Query principal com todos os campos
        var query = supabase.from('quotes').select(
              'id, text, page, type, notes, is_favorite, book_id, books(title, author, cover)',
            );

        if (filteredIds != null && filteredIds.isNotEmpty) {
          query = query.inFilter('id', filteredIds);
        }

        query.order('id', ascending: true);

        if (bookId != null) {
          query.limit(2000);
        } else {
          query.limit(10000);
        }

        final res = await query;
        data = (res as List);

        if (currentSortMode == 'newest') {
          data = data.reversed.toList();
        } else if (currentSortMode == 'random') {
          data.shuffle(Random());
        }
      }

      // 🧩 Logs
      print('🟨 FetchQuotes → Total recebidos: ${data.length}');
      for (var q in data.take(8)) {
        print('🟡 Quote ${q['id']} → book_id=${q['book_id']}');
      }

      // 🔹 Normalização
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
                (favValue is String &&
                    favValue.toLowerCase() == 'true'))
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
      print(
          '💛 FetchQuotes → Favoritas identificadas: $favCount de ${normalized.length} totais');

      return normalized;
    } catch (e) {
      print('❌ Erro ao buscar citações: $e');
      return [];
    }
  }
}
