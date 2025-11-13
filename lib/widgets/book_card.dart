import 'package:flutter/material.dart';
import '../screens/book_quotes_screen.dart';

class BookCard extends StatelessWidget {
  final int bookId;
  final String title;
  final String author;
  final String cover;
  final int quotesCount;

  const BookCard({
    Key? key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.cover,
    required this.quotesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookQuotesScreen(
              bookId: bookId,
              bookTitle: title,
              bookAuthor: author,
              bookCover: cover,
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Capa do livro
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                cover,
                height: 165,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.black26,
                  child: const Icon(Icons.broken_image,
                      color: Colors.white38, size: 28),
                ),
              ),
            ),

            // 🔹 Informações do livro
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$quotesCount citações',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
