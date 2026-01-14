import 'package:supabase_flutter/supabase_flutter.dart';

class VocabularySearchManager {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> search({
    String? rawTerm,
    int? bookId,
  }) async {
    final term = rawTerm?.trim();

    var query = supabase.from('vocabulary').select(
      'id, text, word, notes, page, is_favorite::int, is_active, book_id, books(title, author, cover)',
    );

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }

    if (term != null && term.isNotEmpty) {
      // melhor buscar por word também
      query = query.or('text.ilike.%$term%,word.ilike.%$term%');
    }

    final data = await query.order('id');

    return data.map<Map<String, dynamic>>((e) {
      final v = Map<String, dynamic>.from(e);

      v['is_active'] = v['is_active'] == true || v['is_active'] == 1 ? 1 : 0;
      v['is_favorite'] =
          v['is_favorite'] == true || v['is_favorite'] == 1 ? 1 : 0;

      return v;
    }).toList();
  }
}
