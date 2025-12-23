import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'books_cache_manager.dart';

class BooksSearchManager {
  static final supabase = Supabase.instance.client;

  /// ------------------------------------------------------------
  ///  Função única para todas as buscas de livros
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> search({
    String? rawTerm,
    required String sortMode,          // 'asc', 'desc', 'shuffle', 'rating_desc'
    required String cacheKey,
    bool forceRefresh = false,
  }) async {
    final term = rawTerm?.trim();
    final hasTerm = term != null && term.isNotEmpty;

    List<Map<String, dynamic>> results = [];

    // ------------------------------------------------------------
    // 1) USAR CACHE quando NÃO há termo e NÃO é refresh
    // ------------------------------------------------------------
    if (!hasTerm && !forceRefresh) {
      final cached = await BooksCacheManager.loadBooks();
      if (cached != null && cached.isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(cached);

        // Aplicar sort local ao cache
        final sorted = _applySortLocal(list, sortMode);
        return sorted;
      }
    }

    // ------------------------------------------------------------
    // 2) BUSCA COMPLEXA (AND/OR)
    // ------------------------------------------------------------
    if (hasTerm && _isComplexQuery(term!)) {
      results = await _runComplexSearch(term);
    }

    // ------------------------------------------------------------
    // 3) BUSCA SIMPLES (TERMO ÚNICO)
    // ------------------------------------------------------------
    else if (hasTerm) {
      results = await _runSimpleSearch(term!);
    }

    // ------------------------------------------------------------
    // 4) SEM TERMO → FETCH COMPLETO
    // ------------------------------------------------------------
    else {
      results = await _fetchAllBooks();
    }

    // ------------------------------------------------------------
    // 5) SALVAR CACHE somente quando:
    //    - não tem termo
    //    - resultado não é vazio
    // ------------------------------------------------------------
    if (!hasTerm && results.isNotEmpty) {
      await BooksCacheManager.saveBooks(results);
    }

    // Ordenação final
    return _applySortLocal(results, sortMode);
  }

  /// ------------------------------------------------------------
  /// Detecta operadores AND / OR
  /// ------------------------------------------------------------
  static bool _isComplexQuery(String term) {
    return term.contains(' AND ') || term.contains(' OR ');
  }

  /// ------------------------------------------------------------
  ///  BUSCA COMPLEXA: títulos e autores usando AND/OR
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _runComplexSearch(
    String term,
  ) async {
    final Map<int, Map<String, dynamic>> merged = {};

    final orParts = term.split(' OR ');

    for (final orSegment in orParts) {
      final andParts = orSegment.split(' AND ');

      List<Map<String, dynamic>>? andResult;

      for (final raw in andParts) {
        final clean = raw.trim();
        if (clean.isEmpty) continue;

        final simple = await _runSimpleSearch(clean);

        if (andResult == null) {
          andResult = simple;
        } else {
          final ids = andResult.map((b) => b['id']).toSet();
          andResult =
              simple.where((b) => ids.contains(b['id'])).toList();
        }
      }

      if (andResult != null) {
        for (final item in andResult) {
          merged[item['id']] = item;
        }
      }
    }

    return merged.values.toList();
  }

  /// ------------------------------------------------------------
  /// BUSCA SIMPLES: Supabase LIKE (título + autor)
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _runSimpleSearch(
    String term,
  ) async {
    final res = await supabase
        .from('books')
        .select('id, title, author, cover, rating, quotes(count)')
        .or('title.ilike.%$term%,author.ilike.%$term%');

    final list = List<Map<String, dynamic>>.from(res as List);

    // Contar quotes
    for (final b in list) {
      final quotes = b['quotes'] as Map<String, dynamic>?;
      b['quotes_count'] = quotes?['count'] ?? 0;
    }

    return list;
  }

  /// ------------------------------------------------------------
  /// FETCH COMPLETO (quando sem termo)
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _fetchAllBooks() async {
    final res = await supabase
        .from('books')
        .select('id, title, author, cover, rating, quotes(count)')
        .limit(2000);

    final list = List<Map<String, dynamic>>.from(res as List);

    for (final b in list) {
      final quotes = b['quotes'] as List<dynamic>? ?? [];
      b['quotes_count'] = quotes.length;
    }

    return list;
  }

  /// ------------------------------------------------------------
  /// Ordenação local final
  /// ------------------------------------------------------------
  static List<Map<String, dynamic>> _applySortLocal(
    List<Map<String, dynamic>> list,
    String sortMode,
  ) {
    final items = List<Map<String, dynamic>>.from(list);

    if (sortMode == 'rating_desc') {
      items.removeWhere((b) => b['rating'] == null);
      items.sort((a, b) =>
          (b['rating'] as num).compareTo(a['rating'] as num));
    } else if (sortMode == 'asc') {
      items.sort((a, b) =>
          a['title'].toString().compareTo(b['title'].toString()));
    } else if (sortMode == 'desc') {
      items.sort((a, b) =>
          b['title'].toString().compareTo(a['title'].toString()));
    } else {
      items.shuffle(Random());
    }

    return items;
  }
}
