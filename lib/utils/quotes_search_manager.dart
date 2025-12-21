import 'package:supabase_flutter/supabase_flutter.dart';
import 'quotes_helper.dart';
import 'quotes_cache_manager.dart';

class QuotesSearchManager {
  static final supabase = Supabase.instance.client;

  // 🔥 Normalizador universal de TYPE
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
    required String origin, // 'global', 'favorites', 'book'
    int? bookId,
    String? rawTerm,
    int? typeFilter,
    required String sortMode,
    required String cacheKey,
    bool forceRefresh = false,
    bool onlyActive = true,
  }) async {
    final term = rawTerm?.trim();
    bool hasTerm = term != null && term.isNotEmpty;

    List<Map<String, dynamic>> results = [];

    // ------------------------------------------------------------
    //  1) Cache local
    // ------------------------------------------------------------
    if (!hasTerm && !forceRefresh) {
      final cached = await QuotesCacheManager.loadQuotes(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(cached)
            .map<Map<String, dynamic>>((q) {
          final m = Map<String, dynamic>.from(q);
          m['type'] = _normalizeType(m['type']);
          m['is_active'] = (m['is_active'] is int)
              ? m['is_active']
              : ((m['is_active'] == true) ? 1 : 0);
          return m;
        }).toList();

        if (origin == 'book' && bookId != null) {
          results = list.where((q) => q['book_id'] == bookId).toList();
        } else {
          results = list;
        }

        if (sortMode == 'random') results.shuffle();

        if (typeFilter != null) {
          results = results.where((q) => q['type'] == typeFilter).toList();
        }

        if (onlyActive) {
          results = results.where((q) => q['is_active'] == 1).toList();
        }

        return results;
      }
    }

    // ------------------------------------------------------------
    //  2) Busca complexa (AND / OR)
    // ------------------------------------------------------------
    if (hasTerm && _isComplexQuery(term!)) {
      results = await _runComplexSearch(term, origin, bookId);
    }

    // ------------------------------------------------------------
    //  3) Busca simples via RPC
    // ------------------------------------------------------------
    else if (hasTerm) {
      results = await _runSimpleSearch(term!, origin, bookId);
    }

    // ------------------------------------------------------------
    //  4) Sem termo → carregamento padrão
    // ------------------------------------------------------------
    else {
      results = await _loadDefaultData(
        origin,
        bookId,
        sortMode,
        onlyActive: onlyActive,
      );
    }

    // ------------------------------------------------------------
    //  Filtros adicionais
    // ------------------------------------------------------------
    if (typeFilter != null) {
      results = results.where((q) => q['type'] == typeFilter).toList();
    }

    // Cache persistente
    if (!hasTerm && results.isNotEmpty && onlyActive) {
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
  ///  Busca complexa RPC
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
          q['type'] = _normalizeType(q['type']);
          q['is_active'] = (q['is_active'] is int)
              ? q['is_active']
              : ((q['is_active'] == true) ? 1 : 0);
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
          andResult =
              current.where((q) => ids.contains(q['id'])).toList();
        }
      }

      if (andResult != null) {
        for (final q in andResult) {
          allResults[q['id']] = q;
        }
      }
    }

    var finalList = allResults.values.toList();

    if (origin == 'favorites') {
      finalList = finalList.where((q) {
        final f = q['is_favorite'];
        return f == 1 || f == true || f == '1';
      }).toList();
    }

    if (origin == 'book' && bookId != null) {
      finalList =
          finalList.where((q) => q['book_id'] == bookId).toList();
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
      q['is_active'] = (q['is_active'] is int)
          ? q['is_active']
          : ((q['is_active'] == true) ? 1 : 0);
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
    String sortMode, {
    bool onlyActive = true,
  }) async {
    // 🧠 Caso FAVORITOS → filtra por favoritos
    if (origin == 'favorites') {
      final data = await supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
          )
          .eq('is_favorite', 1)
          .order('id', ascending: true);

      return data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e);
        q['type'] = _normalizeType(q['type']);
        q['is_active'] = (q['is_active'] is int)
            ? q['is_active']
            : ((q['is_active'] == true) ? 1 : 0);
        return q;
      }).toList();
    }

    // 🌍 Caso GLOBAL → busca tudo sem filtros no servidor
    final data = await supabase
        .from('quotes')
        .select(
          'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
        )
        .order('id', ascending: true);

    var list = data.map<Map<String, dynamic>>((e) {
      final q = Map<String, dynamic>.from(e);
      q['type'] = _normalizeType(q['type']);
      q['is_active'] = (q['is_active'] is int)
          ? q['is_active']
          : ((q['is_active'] == true) ? 1 : 0);
      return q;
    }).toList();

    // aplica filtro só depois
    if (onlyActive) {
      list = list.where((q) => q['is_active'] == 1).toList();
    }

    return list;
  }
}
