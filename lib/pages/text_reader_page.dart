import 'package:flutter/material.dart';
import '../models/book.dart';

/// 文字版阅读页：纯文字流，连续滚动，家长照念
class TextReaderPage extends StatelessWidget {
  final Book book;

  const TextReaderPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final allSegments =
        book.pages.expand((p) => p.segments).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          if (book.estimatedMinutes != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('约 ${book.estimatedMinutes} 分钟',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        itemCount: allSegments.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            allSegments[i].text,
            style: const TextStyle(fontSize: 20, height: 1.9),
          ),
        ),
      ),
    );
  }
}
