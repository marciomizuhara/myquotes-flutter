import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnkiCardScreen extends StatelessWidget {
  final Map<String, dynamic> vocab;

  const AnkiCardScreen({
    Key? key,
    required this.vocab,
  }) : super(key: key);


  String get _word =>
      (vocab['word'] ?? '').toString().trim();

  String get _translatedWord =>
      (vocab['translated_word'] ??
              vocab['translation'] ??
              '')
          .toString()
          .trim();

  Future<void> _setStatus(
    BuildContext context,
    String status,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('vocabulary')
        .update({'status': status})
        .eq('id', vocab['id']);

    vocab['status'] = status;

    Navigator.pop(context, status);
  }

  Widget _ankiButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          _word,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // EN term
                    if (_word.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 28),
                        child: Text(
                          _word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),

                    // PT term
                    if (_translatedWord.isNotEmpty)
                      Text(
                        _translatedWord,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      )
                    else
                      const Text(
                        'Sem tradução',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ANKI buttons
          Container(
            padding:
                const EdgeInsets.fromLTRB(8, 8, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
            ),
            child: Row(
              children: [
                _ankiButton(
                  label: 'Again',
                  color: Colors.red.shade700,
                  onTap: () =>
                      _setStatus(context, 'again'),
                ),
                _ankiButton(
                  label: 'Hard',
                  color: Colors.orange.shade700,
                  onTap: () =>
                      _setStatus(context, 'hard'),
                ),
                _ankiButton(
                  label: 'Good',
                  color: Colors.amber.shade700,
                  onTap: () =>
                      _setStatus(context, 'good'),
                ),
                _ankiButton(
                  label: 'Easy',
                  color: Colors.green.shade700,
                  onTap: () =>
                      _setStatus(context, 'easy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
