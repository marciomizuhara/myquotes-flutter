import 'package:supabase_flutter/supabase_flutter.dart';

class QuotesHelper {
  static final supabase = Supabase.instance.client;

  /// Busca citações, com suporte opcional a:
  /// - termo de busca (`term`)
  /// - filtro por tipo (`selectedType`)
  /// - filtro por livro (`bookId`)
  static Future<List<Map<String, dynamic>>> fetchQuotes({
    String? term,
    int? selectedType,
    int? bookId,
  }) async {
    try {
      List data;

      // 🔹 Caso tenha termo de busca → usa a RPC
      if (term != null && term.trim().isNotEmpty) {
        final res = await supabase.rpc('search_quotes', params: {
          'search_term': term.trim(),
        });
        data = (res as List);
      } else {
        // 🔹 Caso contrário → busca normal no banco
        var query = supabase
            .from('quotes')
            .select('id, text, page, type, notes, book_id, books(title, author, cover)')
            .order('id', ascending: false);

        if (bookId != null) {
          query = supabase
              .from('quotes')
              .select('id, text, page, type, notes, book_id, books(title, author, cover)')
              .eq('book_id', bookId)
              .order('id', ascending: false);
        }

        final res = await query;
        data = (res as List);
      }

      // 🔹 Normalização padrão
      var normalized = data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e as Map);
        final bookData = q['books'];
        final Map<String, dynamic> books = (bookData is Map<String, dynamic>)
            ? bookData
            : {
                'title': q['book_title'] ?? '',
                'author': q['book_author'] ?? '',
                'cover': q['book_cover'] ?? '',
              };

        return {
          'id': int.tryParse(q['id'].toString()) ?? 0,
          'page': q['page'],
          'type': q['type']?.toString() ?? '',
          'text': q['text'] ?? '',
          'notes': q['notes'],
          'book_id': q['book_id'],
          'books': books,
        };
      }).toList();

      // 🔹 Aplica o filtro de cor (client-side) se houver
      if (selectedType != null) {
        final typeStr = selectedType.toString();
        normalized = normalized
            .where((q) => (q['type']?.toString() ?? '') == typeStr)
            .toList();
      }

      return normalized;
    } catch (e) {
      print('Erro ao buscar citações: $e');
      return [];
    }
  }
}
