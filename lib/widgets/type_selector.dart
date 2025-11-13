import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TypeSelector {
  static Future<void> show(
    BuildContext context, {
    required int? currentType,
    required int quoteId,
    required Function(int) onTypeChanged,
  }) async {
    final supabase = Supabase.instance.client;

    final colors = {
      1: const Color(0xFF9B2C2C),
      2: const Color(0xFFB8961A),
      3: const Color(0xFF2F7D32),
      4: const Color(0xFF275D8C),
      5: const Color(0xFF118EA8),
      6: const Color(0xFF5A5A5A),
    };

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 6),

            // 🔥 Wrap faz o layout fluir mesmo em telas pequenas, sem overflow
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,   // 🔹 espaçamento horizontal
              runSpacing: 12, // 🔹 espaçamento vertical (se quebrar linha)
              children: colors.entries.map((entry) {
                final isActive = entry.key == currentType;

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await supabase
                          .from('quotes')
                          .update({'type': entry.key})
                          .eq('id', quoteId);

                      onTypeChanged(entry.key);
                      debugPrint('🟢 Tipo da citação atualizado para ${entry.key}');
                    } catch (e) {
                      debugPrint('❌ Erro ao atualizar tipo: $e');
                    }
                  },

                  // 🔥 Área de toque grande e consistente (NÃO estoura o layout)
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 30 : 26,  // 🔹 tamanho otimizado
                      height: isActive ? 30 : 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.value,
                        border: Border.all(
                          color: isActive ? Colors.amber : Colors.white24,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: entry.value.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
