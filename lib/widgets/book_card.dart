import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/book_quotes_screen.dart';
import '../widgets/cached_cover_image.dart';

class BookCard extends StatefulWidget {
  final int bookId;
  final String title;
  final String author;
  final String cover;
  final int quotesCount;
  final double? rating;

  const BookCard({
    Key? key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.cover,
    required this.quotesCount,
    this.rating,
  }) : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  final supabase = Supabase.instance.client;

  double? currentRating;

  @override
  void initState() {
    super.initState();
    currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(covariant BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookId != widget.bookId ||
        oldWidget.rating != widget.rating) {
      currentRating = widget.rating;
    }
  }

  Future<void> _updateRating(double newValue) async {
    final clamped = newValue.clamp(0.0, 5.0);
    final normalized = (clamped * 10).roundToDouble() / 10;

    setState(() {
      currentRating = normalized;
    });

    await supabase
        .from('books')
        .update({'rating': normalized})
        .eq('id', widget.bookId);
  }

  void _openBookQuotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookQuotesScreen(
          bookId: widget.bookId,
          bookTitle: widget.title,
          bookAuthor: widget.author,
          bookCover: widget.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 somente a capa é clicável
          GestureDetector(
            onTap: () => _openBookQuotes(context),
            child: CachedCoverImage(
              url: widget.cover,
              height: 160,
              width: double.infinity,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.quotesCount} citações',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (currentRating != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ➕ aumenta
                        GestureDetector(
                          onTap: () =>
                              _updateRating(currentRating! + 0.1),
                          child: const Text(
                            '+',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          currentRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // ➖ diminui
                        GestureDetector(
                          onTap: () =>
                              _updateRating(currentRating! - 0.1),
                          child: const Text(
                            '−',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
