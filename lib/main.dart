import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'screens/quotes_screen.dart';
import 'screens/books_screen.dart';
import 'screens/characters_screen.dart';
import 'screens/favorites_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lê o .env manualmente dos assets (funciona no Android)
  final envData = await rootBundle.loadString('assets/env.txt');
  final Map<String, String> envMap = {};
  for (var line in envData.split('\n')) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length == 2) {
      envMap[parts[0].trim()] = parts[1].trim();
    }
  }

  // ✅ Inicializa o Supabase diretamente com o mapa
  try {
    debugPrint('🌐 URL: "${envMap['SUPABASE_URL']}"');
    debugPrint('🔑 KEY: "${envMap['SUPABASE_ANON_KEY']}"');
    await Supabase.initialize(
      url: envMap['SUPABASE_URL']!,
      anonKey: envMap['SUPABASE_ANON_KEY']!,
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e, st) {
    debugPrint('❌ Erro ao inicializar Supabase: $e\n$st');
  }

  runApp(MyQuotesApp());
}

class MyQuotesApp extends StatefulWidget {
  @override
  State<MyQuotesApp> createState() => _MyQuotesAppState();
}

class _MyQuotesAppState extends State<MyQuotesApp> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const QuotesScreen(), // 0
      const BooksScreen(), // 1
      const CharactersScreen(), // 2
      const FavoriteQuotesScreen(), // 3 ← nova aba
    ];

    return MaterialApp(
      title: 'MyQuotes',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: pages[_tab],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.format_quote),
              label: 'Quotes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Characters',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}
