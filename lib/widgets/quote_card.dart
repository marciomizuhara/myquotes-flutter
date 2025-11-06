import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';

class QuoteCard extends StatefulWidget {
  final Map<String, dynamic> quote;
  final VoidCallback? onFavoriteChanged;

  const QuoteCard({required this.quote, this.onFavoriteChanged, Key? key})
      : super(key: key);

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final supabase = Supabase.instance.client;
  late TextEditingController _notesCtrl;
  bool _editing = false;
  bool _saving = false;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.quote['notes'] ?? '');

    final raw = widget.quote['is_favorite'];
    _isFavorite = raw == 1 || raw == true || raw == '1';

    debugPrint('🟨 initState → id=${widget.quote['id']} is_favorite=$raw (_isFavorite=$_isFavorite)');
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

  Future<void> _toggleFavorite() async {
    try {
      debugPrint('🟡 Toggle iniciado para ID ${widget.quote['id']} | valor atual=$_isFavorite');

      final newValue = _isFavorite ? 0 : 1;

      setState(() {
        _isFavorite = !_isFavorite;
        widget.quote['is_favorite'] = newValue;
      });

      debugPrint('🟢 Após setState → _isFavorite=$_isFavorite | widget.quote=${widget.quote['is_favorite']}');

      final updated = await supabase
          .from('quotes')
          .update({'is_favorite': newValue})
          .eq('id', widget.quote['id'])
          .select('is_favorite')
          .maybeSingle();

      debugPrint('🧩 Supabase retorno → id=${widget.quote['id']} valor=${updated?['is_favorite']} (${updated?['is_favorite']?.runtimeType})');

      widget.onFavoriteChanged?.call();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar favorito: $e');
    }
  }

  Future<void> _showTypeSelector(BuildContext context, int currentType) async {
    final colors = {
      1: const Color(0xFF9B2C2C), // vermelho
      2: const Color(0xFFB8961A), // amarelo
      3: const Color(0xFF2F7D32), // verde
      4: const Color(0xFF275D8C), // azul
      5: const Color(0xFF118EA8), // ciano
      6: const Color(0xFF5A5A5A), // cinza (quotes de interesse)
    };

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.entries.map((entry) {
              final isActive = entry.key == currentType;
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _updateQuoteType(entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 28 : 22,
                  height: isActive ? 28 : 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.value,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: entry.value.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _updateQuoteType(int newType) async {
    try {
      await supabase
          .from('quotes')
          .update({'type': newType})
          .eq('id', widget.quote['id']);

      setState(() {
        widget.quote['type'] = newType;
      });

      debugPrint('🟢 Tipo da quote atualizado para $newType');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar tipo: $e');
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
                              child: GestureDetector(
                                onTap: () => _showTypeSelector(context, _safeType(q['type'])),
                                child: Text(
                                  'p. ${q['page']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 9.5,
                                  ),
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
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 0, bottom: 0),
              child: _editing
                  ? _buildEditRow(note)
                  : _buildNormalRow(note),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditRow(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
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
    );
  }

  Widget _buildNormalRow(String note) {
    return Row(
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
          flex: 5,
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
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.yellowAccent : Colors.white38,
              size: 17,
            ),
            tooltip: _isFavorite
                ? 'Remover dos favoritos'
                : 'Adicionar aos favoritos',
            onPressed: _toggleFavorite,
          ),
        ),
      ],
    );
  }
}
