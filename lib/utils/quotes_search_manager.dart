import 'package:supabase_flutter/supabase_flutter.dart';
import 'quotes_helper.dart';
import 'quotes_cache_manager.dart';

class QuotesSearchManager {
  static final supabase = Supabase.instance.client;

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
    //  CASO 1: pode usar cache (somente quando NÃO tem busca)
    // ------------------------------------------------------------
    if (!hasTerm && !forceRefresh) {
      final cached = await QuotesCacheManager.loadQuotes(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(cached);

        // filtro de livro (bookId)
        if (origin == 'book' && bookId != null) {
          results = list.where((q) => q['book_id'] == bookId).toList();
        } else {
          results = list;
        }

        // random local se sortMode for random
        if (sortMode == 'random') {
          results.shuffle();
        }

        // filtro local de tipo
        if (typeFilter != null) {
          results = results.where((q) => q['type'] == typeFilter).toList();
        }

        return results;
      }
    }

    // ------------------------------------------------------------
    //  CASO 2: busca complexa → usar RPC
    // ------------------------------------------------------------
    if (hasTerm && _isComplexQuery(term!)) {
      results = await _runComplexSearch(term, origin, bookId);
    }

    // ------------------------------------------------------------
    //  CASO 3: busca simples por termo → fallback Supabase/RPC
    // ------------------------------------------------------------
    else if (hasTerm) {
      results = await _runSimpleSearch(term!, origin, bookId);
    }

    // ------------------------------------------------------------
    //  CASO 4: sem termo → usar fetchQuotes com sortMode
    // ------------------------------------------------------------
    else {
      results = await _loadDefaultData(origin, bookId, sortMode);
    }

    // ------------------------------------------------------------
    //  Filtro local por tipo
    // ------------------------------------------------------------
    if (typeFilter != null) {
      results = results.where((q) => q['type'] == typeFilter).toList();
    }

    // ------------------------------------------------------------
    //  Salvar cache APENAS quando:
    //  - não é busca, e
    //  - resultado não é vazio
    // ------------------------------------------------------------
    if (!hasTerm && results.isNotEmpty) {
      await QuotesCacheManager.saveQuotes(cacheKey, results);
    }

    return results;
  }

  /// ------------------------------------------------------------
  ///  Detecta se a busca contém OR/AND
  /// ------------------------------------------------------------
  static bool _isComplexQuery(String term) {
    return term.contains(' OR ') || term.contains(' AND ');
  }

  /// ------------------------------------------------------------
  ///  Executa busca com AND / OR usando RPC
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
  ///  Busca simples via RPC
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
    if (origin == 'favorites') {
      return await supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, book_id, books(title, author, cover)',
          )
          .eq('is_favorite', 1)
          .order('id', ascending: true);
    }

    return await QuotesHelper.fetchQuotes(
      term: null,
      bookId: bookId,
      sortMode: sortMode,
    );
  }
}
