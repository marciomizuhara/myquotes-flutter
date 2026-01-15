import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _endpoint =
      'https://translate.googleapis.com/translate_a/single';

  static Future<String> translateToPtBr({
    required String text,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return '';

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'client': 'gtx',
      'sl': 'en',
      'tl': 'pt',
      'dt': 't',
      'q': t,
    });

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception(
        'Translation failed (${res.statusCode}): ${res.body}',
      );
    }

    final data = jsonDecode(res.body);

    if (data is! List || data.isEmpty || data[0] is! List) {
      throw Exception('Unexpected translation response');
    }

    final buffer = StringBuffer();

    for (final part in data[0]) {
      if (part is List && part.isNotEmpty) {
        buffer.write(part[0]);
      }
    }

    final translated = buffer.toString().trim();

    if (translated.isEmpty) {
      throw Exception('Empty translation');
    }

    return translated;
  }
}
