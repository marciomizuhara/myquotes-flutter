import 'package:flutter/material.dart';
import '../widgets/quote_reader_view.dart';

class QuoteFullscreenScreen extends StatelessWidget {
  final Map<String, dynamic> quote;

  const QuoteFullscreenScreen({Key? key, required this.quote}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: QuoteReaderView(
        quote: quote,
        onDoubleTap: () => Navigator.pop(context),
      ),
    );
  }
}
