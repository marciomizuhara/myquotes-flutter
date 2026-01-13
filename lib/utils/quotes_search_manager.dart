import 'package:supabase_flutter/supabase_flutter.dart';
import 'quotes_helper.dart';
import 'quotes_cache_manager.dart';

class QuotesSearchManager {
  static final supabase = Supabase.instance.client;

  static int _normalizeType(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

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
    final hasTerm = term != null && term.isNotEmpty;

    if (origin == 'book' && bookId == null) {
      throw Exception('bookId is required when origin == "book"');
    }

    List<Map<String, dynamic>> results = [];

    // ------------------------------------------------------------
    // 🔒 MODO ARQUIVO (INATIVAS)
    // - SEM RPC (porque a RPC provavelmente filtra is_active=1)
    // - SEM CACHE
    // ------------------------------------------------------------
    if (!onlyActive) {
      results = await _loadInactiveData(
        origin,
        bookId,
        term: hasTerm ? term : null,
      );

      if (typeFilter != null) {
        results = results.where((q) => q['type'] == typeFilter).toList();
      }

      if (sortMode == 'random') results.shuffle();
      return results;
    }

    // ------------------------------------------------------------
    // 1) CACHE (SOMENTE PARA ATIVAS)
    // ------------------------------------------------------------
    if (onlyActive && !hasTerm && !forceRefresh) {
      final cached = await QuotesCacheManager.loadQuotes(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        results = cached.map<Map<String, dynamic>>((q) {
          final m = Map<String, dynamic>.from(q);
          m['type'] = _normalizeType(m['type']);
          m['is_active'] =
              (m['is_active'] is int) ? m['is_active'] : ((m['is_active'] == true) ? 1 : 0);
          return m;
        }).toList();

        if (origin == 'book') {
          results = results.where((q) => q['book_id'] == bookId).toList();
        }

        if (typeFilter != null) {
          results = results.where((q) => q['type'] == typeFilter).toList();
        }

        results = results.where((q) => q['is_active'] == 1).toList();

        if (sortMode == 'random') results.shuffle();
        return results;
      }
    }

    // ------------------------------------------------------------
    // 2) BUSCA COMPLEXA
    // ------------------------------------------------------------
    if (hasTerm && _isComplexQuery(term!)) {
      results = await _runComplexSearch(term, origin, bookId);
    }

    // ------------------------------------------------------------
    // 3) BUSCA SIMPLES
    // ------------------------------------------------------------
    else if (hasTerm) {
      results = await _runSimpleSearch(term!, origin, bookId);
    }

    // ------------------------------------------------------------
    // 4) DEFAULT
    // ------------------------------------------------------------
    else {
      results = await _loadDefaultData(
        origin,
        bookId,
        onlyActive: onlyActive,
      );
    }

    if (typeFilter != null) {
      results = results.where((q) => q['type'] == typeFilter).toList();
    }

    // ------------------------------------------------------------
    // 5) SALVAR CACHE (SOMENTE ATIVAS)
    // ------------------------------------------------------------
    if (!hasTerm && results.isNotEmpty && onlyActive) {
      await QuotesCacheManager.saveQuotes(cacheKey, results);
    }

    return results;
  }

  static bool _isComplexQuery(String term) {
    return term.contains(' OR ') || term.contains(' AND ');
  }

  static Future<List<Map<String, dynamic>>> _runComplexSearch(
    String term,
    String origin,
    int? bookId,
  ) async {
    final Map<int, Map<String, dynamic>> merged = {};
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
          q['is_active'] =
              (q['is_active'] is int) ? q['is_active'] : ((q['is_active'] == true) ? 1 : 0);
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
          merged[q['id']] = q;
        }
      }
    }

    var list = merged.values.toList();

    if (origin == 'favorites') {
      list = list.where((q) => q['is_favorite'] == 1).toList();
    }

    if (origin == 'book') {
      list = list.where((q) => q['book_id'] == bookId).toList();
    }

    return list;
  }

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
      q['is_active'] =
          (q['is_active'] is int) ? q['is_active'] : ((q['is_active'] == true) ? 1 : 0);
      q['books'] = {
        'title': q['book_title'],
        'author': q['book_author'],
        'cover': q['book_cover'],
      };
      return q;
    }).toList();

    if (origin == 'favorites') {
      list = list.where((q) => q['is_favorite'] == 1).toList();
    }

    if (origin == 'book') {
      list = list.where((q) => q['book_id'] == bookId).toList();
    }

    return list;
  }

  static Future<List<Map<String, dynamic>>> _loadDefaultData(
    String origin,
    int? bookId, {
    bool onlyActive = true,
  }) async {
    if (origin == 'favorites') {
      final data = await supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
          )
          .eq('is_favorite', 1)
          .order('id');

      var list = data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e);
        q['type'] = _normalizeType(q['type']);
        q['is_active'] = q['is_active'] == true || q['is_active'] == 1 ? 1 : 0;
        return q;
      }).toList();

      if (onlyActive) {
        list = list.where((q) => q['is_active'] == 1).toList();
      }

      return list;
    }

    if (origin == 'book') {
      final data = await supabase
          .from('quotes')
          .select(
            'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
          )
          .eq('book_id', bookId!)
          .order('id');

      var list = data.map<Map<String, dynamic>>((e) {
        final q = Map<String, dynamic>.from(e);
        q['type'] = _normalizeType(q['type']);
        q['is_active'] = q['is_active'] == true || q['is_active'] == 1 ? 1 : 0;
        return q;
      }).toList();

      if (onlyActive) {
        list = list.where((q) => q['is_active'] == 1).toList();
      }

      return list;
    }

    // 🌍 GLOBAL
    final data = await supabase
        .from('quotes')
        .select(
          'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
        )
        .order('id');

    var list = data.map<Map<String, dynamic>>((e) {
      final q = Map<String, dynamic>.from(e);
      q['type'] = _normalizeType(q['type']);
      q['is_active'] = q['is_active'] == true || q['is_active'] == 1 ? 1 : 0;
      return q;
    }).toList();

    if (onlyActive) {
      list = list.where((q) => q['is_active'] == 1).toList();
    }

    return list;
  }

  static Future<List<Map<String, dynamic>>> _loadInactiveData(
    String origin,
    int? bookId, {
    String? term,
  }) async {
    var query = supabase
        .from('quotes')
        .select(
          'id, text, page, type, notes, is_favorite::int, is_active, book_id, books(title, author, cover)',
        )
        .eq('is_active', 0);

    if (origin == 'favorites') {
      query = query.eq('is_favorite', 1);
    }

    if (origin == 'book') {
      query = query.eq('book_id', bookId!);
    }

    if (term != null && term.trim().isNotEmpty) {
      query = query.ilike('text', '%${term.trim()}%');
    }

    final data = await query.order('id');

    return data.map<Map<String, dynamic>>((e) {
      final q = Map<String, dynamic>.from(e);
      q['type'] = _normalizeType(q['type']);
      q['is_active'] = 0;
      return q;
    }).toList();
  }
}
