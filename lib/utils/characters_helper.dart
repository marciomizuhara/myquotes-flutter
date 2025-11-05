import 'package:supabase_flutter/supabase_flutter.dart';

class CharactersHelper {
  static final supabase = Supabase.instance.client;

  /// Busca personagens do Supabase com suporte a modo (random | asc | desc)
  /// e filtragem opcional por [bookId].
  static Future<List<Map<String, dynamic>>> fetchCharacters({
    String orderMode = 'random',
    int? bookId,
  }) async {
    try {
      var query = supabase
          .from('characters')
          .select('id, name, description, rating, tags, books(title, cover)');

      if (bookId != null) {
        query = query.eq('book_id', bookId);
      }

      List<Map<String, dynamic>> data;

      if (orderMode == 'desc') {
        final res = await query.order('rating', ascending: false);
        data = List<Map<String, dynamic>>.from(res as List);
      } else if (orderMode == 'asc') {
        final res = await query.order('rating', ascending: true);
        data = List<Map<String, dynamic>>.from(res as List);
      } else {
        final res = await query.order('id', ascending: true).limit(200);
        data = List<Map<String, dynamic>>.from(res as List);
        data.shuffle();
      }

      return data;
    } catch (e) {
      print('Erro ao buscar personagens: $e');
      return [];
    }
  }
}
