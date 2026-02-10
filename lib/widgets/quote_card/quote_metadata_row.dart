import 'package:flutter/material.dart';

class QuoteMetadataRow extends StatelessWidget {
  final Map<String, dynamic> book;

  const QuoteMetadataRow({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
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
    );
  }
}
