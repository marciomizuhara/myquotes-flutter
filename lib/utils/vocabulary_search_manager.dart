import 'package:supabase_flutter/supabase_flutter.dart';

class VocabularySearchManager {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> search({
    String? rawTerm,
    int? bookId,
  }) async {
    final term = rawTerm?.trim();

    var query = supabase.from('vocabulary').select(
      'id, text, word, translation, translated_word, status, notes, page, is_favorite::int, is_active, book_id, books(title, author, cover)',
    );

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }

    if (term != null && term.isNotEmpty) {
      query = query.or('text.ilike.%$term%,word.ilike.%$term%');
    }

    // sempre determinístico no backend
    final data = await query.order('id');

    final list = data.map<Map<String, dynamic>>((e) {
      final v = Map<String, dynamic>.from(e);

      v['is_active'] =
          v['is_active'] == true || v['is_active'] == 1 ? 1 : 0;

      v['is_favorite'] =
          v['is_favorite'] == true || v['is_favorite'] == 1 ? 1 : 0;

      v['translation'] = (v['translation'] ?? '').toString();
      v['translated_word'] =
          (v['translated_word'] ?? '').toString();

      // 🧠 status Anki-like (again | hard | good | easy)
      v['status'] = (v['status'] ?? '').toString();

      return v;
    }).toList();

    // 🎲 aleatoriza SOMENTE quando não há busca
    if (term == null || term.isEmpty) {
      list.shuffle();
    }

    return list;
  }
}
