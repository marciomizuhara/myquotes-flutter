import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class BooksCacheManager {
  static const String cacheKey = 'books_cache_v1';

  static Future<Box> _openBox() async {
    return await Hive.openBox('books_cache_box');
  }

  // 🔹 Carrega lista completa de livros
  static Future<List<Map<String, dynamic>>?> loadBooks() async {
    final box = await _openBox();
    final raw = box.get(cacheKey);
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 🔹 Salva lista completa de livros
  static Future<void> saveBooks(List<Map<String, dynamic>> books) async {
    final box = await _openBox();
    final encoded = jsonEncode(books);
    await box.put(cacheKey, encoded);
  }

  // 🔹 Limpa o cache
  static Future<void> clear() async {
    final box = await _openBox();
    await box.delete(cacheKey);
  }
}
