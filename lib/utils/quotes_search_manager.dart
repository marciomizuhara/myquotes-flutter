import 'package:supabase_flutter/supabase_flutter.dart';
import 'quotes_helper.dart';
import 'quotes_cache_manager.dart';

class QuotesSearchManager {
  static final supabase = Supabase.instance.client;

  // 🔥 Normalizador universal de TYPE (resolve o bug do Favorites)
  static int _normalizeType(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  /// ------------------------------------------------------------
  ///  Função única para todas as buscas do app
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> search({
    required String origin,            // 'global', 'favorites', 'book'
    int? bookId,
    String? rawTerm,
    int? typeFilter,
    required String sortMode,
    required String cacheKey,
    bool forceRefresh = false,
  }) async {
    final term = rawTerm?.trim();
    bool hasTerm = term != null && term.isNotEmpty;

    List<Map<String, dynamic>> results = [];

    // ------------------------------------------------------------
    //  CASO 1: usar cache (somente quando NÃO tem busca)
    // ------------------------------------------------------------
    if (!hasTerm && !forceRefresh) {
      final cached = await QuotesCacheManager.loadQuotes(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(cached);

        if (origin == 'book' && bookId != null) {
          results = list.where((q) => q['book_id'] == bookId).toList();
        } else {
          results = list;
        }

        if (sortMode == 'random') {
          results.shuffle();
        }

        if (typeFilter != null) {
          results = results.where((q) => q['type'] == typeFilter).toList();
        }

        return results;
      }
    }

    // ------------------------------------------------------------
    //  CASO 2: busca complexa (AND/OR)
    // ------------------------------------------------------------
    if (hasTerm && _isComplexQuery(term!)) {
      results = await _runComplexSearch(term, origin, bookId);
    }

    // ------------------------------------------------------------
    //  CASO 3: busca simples via RPC
    // ------------------------------------------------------------
    else if (hasTerm) {
      results = await _runSimpleSearch(term!, origin, bookId);
    }

    // ------------------------------------------------------------
    //  CASO 4: sem termo → carregar padrão
    // ------------------------------------------------------------
    else {
      results = await _loadDefaultData(origin, bookId, sortMode);
    }

    // ------------------------------------------------------------
    //  Filtro local por tipo (dependente do TYPE NORMALIZADO!!)
    // ------------------------------------------------------------
    if (typeFilter != null) {
      results = results.where((q) => q['type'] == typeFilter).toList();
    }

    // ------------------------------------------------------------
    //  Salva cache apenas quando:
    //  - não tem busca
    //  - resultado não é vazio
    // ------------------------------------------------------------
    if (!hasTerm && results.isNotEmpty) {
      await QuotesCacheManager.saveQuotes(cacheKey, results);
    }

    return results;
  }

  /// ------------------------------------------------------------
  ///  Detecta OR/AND
  /// ------------------------------------------------------------
  static bool _isComplexQuery(String term) {
    return term.contains(' OR ') || term.contains(' AND ');
  }

  /// ------------------------------------------------------------
  ///  Busca complexa usando RPC
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _runComplexSearch(
    String term,
    String origin,
    int? bookId,
  ) async {
    final Map<int, Map<String, dynamic>> allResults = {};

    final orParts = term.split(' OR ');

    for (final orSegment in orParts) {
      final andParts = orSegment.split(' AND ');
      List<Map<String, dynamic>>? andResult;

      for (final raw in andParts) {
        final clean = raw.replaceAll('"', '').trim();
        if (clean.isEmpty) continue;

        final res = await supabase.rpc('search_quotes', params: {
          'search_term': clean,
        });

        final current = (res as List).map<Map<String, dynamic>>((e) {
          final q = Map<String, dynamic>.from(e);

          // normaliza TYPE
          q['type'] = _normalizeType(q['type']);

          q['books'] = {
            'title': q['book_title'],
            'author': q['book_author'],
            'cover': q['book_cover'],
          };
          return q;
        }).toList();

        if (andResult == null) {
          andResult = current;
        } else {
          final ids = andResult.map((q) => q['id']).toSet();
          andResult = current.where((q) => ids.contains(q['id'])).toList();
        }
      }

      if (andResult != null) {
        for (final q in andResult) {
          allResults[q['id']] = q;
        }
      }
    }

    var finalList = allResults.values.toList();

    // filtra favorito
    if (origin == 'favorites') {
      finalList = finalList.where((q) {
        final f = q['is_favorite'];
        return f == 1 || f == true || f == '1';
      }).toList();
    }

    // filtra por livro
    if (origin == 'book' && bookId != null) {
      finalList = finalList.where((q) => q['book_id'] == bookId).toList();
    }

    return finalList;
  }

  /// ------------------------------------------------------------
  ///  Busca simples RPC
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _runSimpleSearch(
    String term,
    String origin,
    int? bookId,
  ) async {
    final res = await supabase.rpc('search_quotes', params: {
      'search_term': term,
    });

    var list = (res as List).map<Map<String, dynamic>>((e) {
      final q = Map<String, dynamic>.from(e);

      q['type'] = _normalizeType(q['type']);

      q['books'] = {
        'title': q['book_title'],
        'author': q['book_author'],
        'cover': q['book_cover'],
      };
      return q;
    }).toList();

    if (origin == 'favorites') {
      list = list.where((q) {
        final f = q['is_favorite'];
        return f == 1 || f == true || f == '1';
      }).toList();
    }

    if (origin == 'book' && bookId != null) {
      list = list.where((q) => q['book_id'] == bookId).toList();
    }

    return list;
  }

  /// ------------------------------------------------------------
  ///  Carregamento padrão (sem termo)
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _loadDefaultData(
    String origin,
    int? bookId,
    String sortMode,
  ) async {

    // ⭐ AQUI ESTAVA O BUG REAL
    // Favoritos vinham com TYPE SUJO
    if (origin == 'favorites') {
      final data = await supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, book_id, books(title, author, cover)',
          )
          .eq('is_favorite', 1)
          .order('id', ascending: true);

      return data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e);

        // 🔥 normalização obrigatória
        q['type'] = _normalizeType(q['type']);

        return q;
      }).toList();
    }

    return await QuotesHelper.fetchQuotes(
      term: null,
      bookId: bookId,
      sortMode: sortMode,
    );
  }
}
