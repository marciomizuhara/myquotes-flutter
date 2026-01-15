import 'package:flutter/material.dart';

class QuotesTopControls extends StatelessWidget {
  final List<Widget> typeDots;
  final Widget? leadingAction;
  final List<Widget> trailingActions;

  const QuotesTopControls({
    Key? key,
    required this.typeDots,
    this.leadingAction,
    required this.trailingActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ⬅️ AÇÕES FIXAS À ESQUERDA (👁️ + ABC)
          if (leadingAction != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: leadingAction!,
            ),

          // 🔵 BOLINHAS — SEMPRE À ESQUERDA, SCROLL SE PRECISAR
          Expanded(
            child: SizedBox(
              height: 28, // altura fixa evita "pulos" de layout
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 6),
                physics: const BouncingScrollPhysics(),
                children: typeDots,
              ),
            ),
          ),

          // ➡️ AÇÕES FIXAS À DIREITA
          Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingActions,
          ),
        ],
      ),
    );
  }
}
