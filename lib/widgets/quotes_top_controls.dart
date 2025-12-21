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
        children: [
          // grupo esquerdo: tipos + ação opcional (👁️)
          Row(
            children: [
              ...typeDots,
              if (leadingAction != null) leadingAction!,
            ],
          ),

          const Spacer(),

          // grupo direito: ações
          Row(
            children: trailingActions,
          ),
        ],
      ),
    );
  }
}
