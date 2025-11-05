import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';

class QuoteCard extends StatefulWidget {
  final Map<String, dynamic> quote;
  const QuoteCard({required this.quote, Key? key}) : super(key: key);

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final supabase = Supabase.instance.client;
  late TextEditingController _notesCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.quote['notes'] ?? '');
  }

  Future<void> _updateNotes(String newText) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await supabase
          .from('quotes')
          .update({'notes': newText})
          .eq('id', widget.quote['id']);
    } catch (e) {
      debugPrint('Erro ao atualizar nota: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  int _safeType(dynamic rawType) {
    if (rawType == null) return 0;
    if (rawType is int) return rawType;
    if (rawType is num) return rawType.toInt();
    return int.tryParse(rawType.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final Map<String, dynamic> book =
        (q['books'] is Map<String, dynamic>) ? q['books'] as Map<String, dynamic> : {};
    final String cover = (book['cover'] ?? '').toString();

    final color = colorByType(_safeType(q['type']));
    final note = _notesCtrl.text.trim();

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal: capa + texto
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cover.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      cover,
                      width: 48,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          Container(width: 48, height: 70, color: Colors.black26),
                    ),
                  ),
                if (cover.isNotEmpty) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['text'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.3,
                          fontSize: 13.5,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  book['author'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (q['page'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 1),
                              child: Text(
                                'p. ${q['page']}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Nota: linha abaixo, alinhada à esquerda com o ícone
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 0, bottom: 0),
              child: _editing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _notesCtrl,
                            maxLines: null,
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                              height: 1.1,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Editar nota...',
                              hintStyle: TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.check, color: Colors.green, size: 17),
                          tooltip: 'Salvar nota',
                          onPressed: () async {
                            final newText = _notesCtrl.text.trim();
                            await _updateNotes(newText);
                            setState(() => _editing = false);
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 17),
                          tooltip: 'Cancelar edição',
                          onPressed: () {
                            setState(() {
                              _notesCtrl.text = note;
                              _editing = false;
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_note, color: Colors.white70, size: 17),
                          tooltip: 'Editar nota',
                          onPressed: () => setState(() => _editing = true),
                        ),
                        Expanded(
                          child: Text(
                            note.isEmpty ? '' : note,
                            style: TextStyle(
                              color: note.isEmpty ? Colors.white38 : Colors.white70,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
            )

          ],
        ),
      ),
    );
  }
}
