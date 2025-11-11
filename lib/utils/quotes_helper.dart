import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../utils/quotes_cache_manager.dart';

class QuotesHelper {
  static final supabase = Supabase.instance.client;
  static String currentSortMode = 'none';
  static const _globalCacheKey = 'quotes_global_cache_v1';

  // 🔹 Busca principal de citações (com suporte a "OR" e "AND")
  static Future<List<Map<String, dynamic>>> fetchQuotes({
    String? term,
    int? selectedType,
    int? bookId,
    String? sortMode,
  }) async {
    try {
      List<dynamic> data = [];

      // 🔸 Caso 1: busca geral sem termo, modo random com cache
      if ((term == null || term.trim().isEmpty) &&
          (sortMode == 'random' || currentSortMode == 'random')) {
        final cached = await QuotesCacheManager.loadQuotes(_globalCacheKey);
        if (cached != null && cached.isNotEmpty) {
          print('💾 [CACHE] ${cached.length} citações carregadas do cache global.');
          final shuffled = List<Map<String, dynamic>>.from(cached)..shuffle();
          return shuffled;
        }

        print('⚙️ Nenhum cache encontrado — buscando todas as citações do Supabase...');
        final allData = await _fetchAllQuotesFromSupabase(bookId: bookId);

        // ✅ só salva se NÃO for pesquisa nem modo especial
        if ((term == null || term.trim().isEmpty) &&
            (sortMode == 'random' || currentSortMode == 'random')) {
          await QuotesCacheManager.saveQuotes(_globalCacheKey, allData);
          print('📦 Cache inicial criado com ${allData.length} citações.');
        } else {
          print('⚠️ Cache global não salvo (modo diferente ou pesquisa ativa).');
        }

        final shuffled = List<Map<String, dynamic>>.from(allData)..shuffle();
        return shuffled;
      }

      // 🔸 Caso 2: modo especial de "uma citação por livro"
      if (sortMode == 'one_per_book_desc' || currentSortMode == 'one_per_book') {
        print('📚 Modo especial: uma citação por livro (DESC)');
        final res = await supabase.rpc('get_one_random_quote_per_book');
        data = (res as List);
      } else if (sortMode == 'one_per_book_asc' ||
          currentSortMode == 'one_per_book_asc') {
        print('📗 Modo especial: uma citação por livro (ASC)');
        final res = await supabase.rpc('get_one_random_quote_per_book_asc');
        data = (res as List);
      }

      // 🔸 Caso 3: busca com termo — mantém lógica avançada AND/OR
      else if (term != null && term.trim().isNotEmpty) {
        final rawTerm = term.trim();
        print('🔎 Buscando com termo: "$rawTerm"');

        if (rawTerm.contains(' OR ') || rawTerm.contains(' AND ')) {
          final orParts = rawTerm.split(' OR ');
          final Map<int, Map<String, dynamic>> allResults = {};

          for (var orSegment in orParts) {
            final andParts = orSegment.split(' AND ');
            List<Map<String, dynamic>>? andResult;

            for (var raw in andParts) {
              final clean = raw.replaceAll('"', '').trim();
              if (clean.isEmpty) continue;

              final res =
                  await supabase.rpc('search_quotes', params: {'search_term': clean});
              final List<Map<String, dynamic>> current =
                  (res as List).map((e) => Map<String, dynamic>.from(e)).toList();

              if (andResult == null) {
                andResult = current;
              } else {
                final ids = andResult.map((q) => q['id']).toSet();
                andResult = current.where((q) => ids.contains(q['id'])).toList();
              }
            }

            if (andResult != null) {
              for (final q in andResult) {
                final id = int.tryParse(q['id'].toString()) ?? 0;
                if (id > 0) allResults[id] = q;
              }
            }
          }

          data = allResults.values.toList();
          print('🔍 Busca combinada OR/AND → ${data.length} resultados totais');
        } else {
          final res =
              await supabase.rpc('search_quotes', params: {'search_term': rawTerm});
          data = (res as List);
        }

        // 🔹 Filtro opcional por livro
        if (bookId != null) {
          data = data
              .where((q) =>
                  q['book_id'] != null &&
                  int.tryParse(q['book_id'].toString()) == bookId)
              .toList();
          print('📘 Filtro pós-RPC → ${data.length} citações do book_id=$bookId');
        }
      }

      // 🔸 Caso 4: fallback → busca geral (sem termo e sem cache)
      else {
        data = await _fetchAllQuotesFromSupabase(bookId: bookId);
      }

      // 🔹 Ordenações locais (exceto random)
      if (sortMode == 'one_per_book_asc') {
        data.sort((a, b) => (a['book_id'] ?? 0).compareTo(b['book_id'] ?? 0));
        print('⬆️ Ordenação crescente aplicada.');
      } else if (sortMode == 'one_per_book_desc') {
        data.sort((a, b) => (b['book_id'] ?? 0).compareTo(a['book_id'] ?? 0));
        print('⬇️ Ordenação decrescente aplicada.');
      }

      // 🔹 Normalização e filtro final
      final normalized = _normalizeQuotes(data, selectedType);
      final favCount = normalized.where((q) => q['is_favorite'] == 1).length;
      print('💛 Total favoritas: $favCount de ${normalized.length} totais.');
      return normalized;
    } catch (e) {
      print('❌ Erro em fetchQuotes: $e');
      return [];
    }
  }

  // 🔸 Função auxiliar: busca todas as citações com paginação
  static Future<List<Map<String, dynamic>>> _fetchAllQuotesFromSupabase({
    int? bookId,
  }) async {
    try {
      List<int>? filteredIds;
      if (bookId != null) {
        final idsRes =
            await supabase.from('quotes').select('id').eq('book_id', bookId);
        filteredIds = (idsRes as List)
            .map<int>((e) => int.tryParse(e['id'].toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }

      var query = supabase.from('quotes').select(
            'id, text, page, type, notes, is_favorite, book_id, books(title, author, cover)',
          );

      if (filteredIds != null && filteredIds.isNotEmpty) {
        query = query.inFilter('id', filteredIds);
      }

      query.order('id', ascending: true);

      // 🔹 Paginação automática
      List<dynamic> allData = [];
      int start = 0;
      const int step = 1000;

      while (true) {
        final res = await query.range(start, start + step - 1);
        final batch = res as List;
        if (batch.isEmpty) break;
        allData.addAll(batch);

        print('📥 Página ${start ~/ step + 1} carregada: ${batch.length} itens (total ${allData.length})');
        if (batch.length < step) break;
        start += step;
      }

      print('📚 _fetchAllQuotesFromSupabase → ${allData.length} citações totais');
      return _normalizeQuotes(allData, null);
    } catch (e) {
      print('❌ Erro em _fetchAllQuotesFromSupabase: $e');
      return [];
    }
  }

  // 🔸 Normalização e filtro de tipo
  static List<Map<String, dynamic>> _normalizeQuotes(
      List<dynamic> data, int? selectedType) {
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
              (favValue is String && favValue.toLowerCase() == 'true'))
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

    if (selectedType != null) {
      normalized = normalized.where((q) => q['type'] == selectedType).toList();
    }

    return normalized;
  }
  // 🔹 Buscar lista de autores e contagem de livros
  static Future<List<Map<String, dynamic>>> fetchWriters() async {
    try {
      final res = await supabase
          .from('books')
          .select('author')
          .order('author', ascending: true);

      final Map<String, int> countMap = {};
      for (final b in res) {
        final author = (b['author'] ?? 'Autor desconhecido').toString();
        countMap[author] = (countMap[author] ?? 0) + 1;
      }

      final data = countMap.entries
          .map((e) => {
                'author': e.key,
                'book_count': e.value,
              })
          .toList()
        ..sort((a, b) => a['author']
            .toString()
            .toLowerCase()
            .compareTo(b['author'].toString().toLowerCase()));

      print('📚 fetchWriters → ${data.length} autores carregados');
      return data;
    } catch (e) {
      print('❌ Erro ao buscar autores: $e');
      return [];
    }
  }

  // 🔹 Buscar livros de um autor específico
  static Future<List<Map<String, dynamic>>> fetchBooksByAuthor(String author) async {
    try {
      final res = await supabase
          .from('books')
          .select('id, title, author, cover')
          .eq('author', author)
          .order('title', ascending: true);

      final data = (res as List)
          .map<Map<String, dynamic>>((b) => {
                'id': int.tryParse(b['id'].toString()) ?? 0,
                'title': b['title'] ?? '',
                'author': b['author'] ?? '',
                'cover': b['cover'] ?? '',
              })
          .toList();

      print('📖 fetchBooksByAuthor("$author") → ${data.length} livros encontrados');
      return data;
    } catch (e) {
      print('❌ Erro ao buscar livros do autor "$author": $e');
      return [];
    }
  }



}
