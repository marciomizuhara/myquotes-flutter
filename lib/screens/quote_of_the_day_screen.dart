import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';
import '../utils/quotes_helper.dart';
import '../widgets/type_selector.dart';
import '../widgets/quote_reader_view.dart';


class QuoteOfTheDayScreen extends StatefulWidget {
  const QuoteOfTheDayScreen({Key? key}) : super(key: key);

  @override
  State<QuoteOfTheDayScreen> createState() => _QuoteOfTheDayScreenState();
}

class _QuoteOfTheDayScreenState extends State<QuoteOfTheDayScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _quote;
  bool _loading = true;

  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _notesCtrl = TextEditingController();
  bool _editingNote = false;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fetchQuoteOfTheDay();
  }

  Future<void> _fetchQuoteOfTheDay() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    setState(() => _loading = true);

    try {
      final existing = await supabase
          .from('quote_of_the_day')
          .select('quote_id, date_key')
          .eq('date_key', today)
          .order('created_at', ascending: false)
          .limit(1);

      if (existing.isNotEmpty) {
        final quoteId = existing.first['quote_id'];

        final res = await supabase
            .from('quotes')
            .select('id, text, notes, is_favorite, page, type, books(title, author, cover)')
            .eq('id', quoteId)
            .maybeSingle();

        if (res != null) {
          setState(() {
            _quote = Map<String, dynamic>.from(res);
            _notesCtrl.text = _quote?['notes'] ?? '';
            _loading = false;
          });
          _controller.forward(from: 0);
          return;
        }
      }

      final allQuotes = await QuotesHelper.fetchQuotes();
      if (allQuotes.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final seed = int.parse(today);
      final random = Random(seed);
      final index = random.nextInt(allQuotes.length);
      final q = allQuotes[index];

      await supabase.from('quote_of_the_day').insert({
        'quote_id': q['id'],
        'date_key': today,
      });

      setState(() {
        _quote = q;
        _notesCtrl.text = q['notes'] ?? '';
        _loading = false;
      });
      _controller.forward(from: 0);
    } catch (e) {
      debugPrint('❌ Erro ao buscar/registrar Quote do Dia: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQuoteType(int newType) async {
    try {
      await supabase
          .from('quotes')
          .update({'type': newType})
          .eq('id', _quote?['id']);
      setState(() => _quote?['type'] = newType);
    } catch (e) {
      debugPrint('❌ Erro ao atualizar tipo: $e');
    }
  }

  Future<void> _updateNotes(String newText) async {
    if (_savingNote || _quote == null) return;
    setState(() => _savingNote = true);
    try {
      await supabase
          .from('quotes')
          .update({'notes': newText})
          .eq('id', _quote!['id']);
      setState(() => _quote!['notes'] = newText);
    } catch (e) {
      debugPrint('❌ Erro ao salvar nota: $e');
    } finally {
      setState(() => _savingNote = false);
    }
  }

  void _copyQuote(Map<String, dynamic> q) {
    final text = q['text'] ?? '';
    final author = q['books']?['author'] ?? 'Autor desconhecido';
    final title = q['books']?['title'] ?? 'Livro não informado';
    final formatted = '$text\n\n$author - $title';
    Clipboard.setData(ClipboardData(text: formatted));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Citação copiada!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_quote == null) {
      return const Center(child: Text('Nenhuma citação disponível.'));
    }

    final q = _quote!;
    final book = q['books'] ?? {};
    final bgColor = colorByType(q['type']);
    final cover = (book['cover'] ?? '').toString();
    final title = (book['title'] ?? '').toString();
    final author = (book['author'] ?? '').toString();
    final note = _notesCtrl.text.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: QuoteReaderView(
        quote: _quote!,
        onDoubleTap: () => _copyQuote(_quote!),
      ),
    );
  }
}
