import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _endpoint = 'https://libretranslate.com/translate';

  static Future<String> translateToPtBr({
    required String text,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return '';

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'q': t,
        'source': 'en',
        'target': 'pt',
        'format': 'text',
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Translation failed (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body);
    final translated = (data['translatedText'] ?? '').toString().trim();

    if (translated.isEmpty) {
      throw Exception('Empty translation');
    }

    return translated;
  }
}
