import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class QuotesCacheManager {
  static const _boxName = 'quotes_cache_box';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Future<void> saveQuotes(String key, List<Map<String, dynamic>> quotes) async {
    final box = Hive.box<String>(_boxName);
    try {
      final jsonData = jsonEncode(quotes); // 🔹 serializa antes de salvar
      await box.put(key, jsonData);
      print('📦 Cache salvo: $key (${quotes.length} itens)');
    } catch (e) {
      print('⚠️ Erro ao salvar cache Hive ($key): $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> loadQuotes(String key) async {
    final box = Hive.box<String>(_boxName);
    try {
      final cachedJson = box.get(key);
      if (cachedJson == null) return null;
      final decoded = jsonDecode(cachedJson) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('⚠️ Erro ao carregar cache Hive ($key): $e');
      return null;
    }
  }

  static Future<void> clearCache(String? key) async {
    final box = Hive.box<String>(_boxName);
    try {
      if (key == null) {
        await box.clear();
        print('🧹 Cache Hive limpo (tudo).');
      } else {
        await box.delete(key);
        print('🧹 Cache Hive limpo (chave: $key).');
      }
    } catch (e) {
      print('⚠️ Erro ao limpar cache Hive: $e');
    }
  }
}
