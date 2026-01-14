import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✅ adicionado

// Utils
import 'utils/quotes_cache_manager.dart'; // ✅ novo módulo
import 'utils/books_cache_manager.dart';
import 'utils/books_search_manager.dart';

// Screens
import 'screens/quotes_screen.dart';
import 'screens/books_screen.dart';
import 'screens/characters_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/quote_of_the_day_screen.dart';
import 'screens/writers_screen.dart'; // 🆕 nova tela adicionada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lê o .env manualmente dos assets (funciona no Android)
  final envData = await rootBundle.loadString('env.txt');
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


  // ✅ Inicialização do Hive e do CacheManager (na ordem certa)
  try {
    await Hive.initFlutter(); // inicializa o Hive
    await QuotesCacheManager.init(); // abre a box antes do runApp
    debugPrint('💾 Hive Cache Manager initialized com sucesso');
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar Hive: $e');
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
      const QuotesScreen(),           // 0
      const QuoteOfTheDayScreen(),    // 1
      const FavoriteQuotesScreen(),   // 2
      const BooksScreen(),            // 3
      const WritersScreen(),          // 4 🆕 nova tela
      const CharactersScreen(),       // 5
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
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Quote of the Day',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Writers', // 🆕 nova aba
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Characters',
            ),
          ],
        ),
      ),
    );
  }
}
