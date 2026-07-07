import 'package:flutter/material.dart';
import '../models/book.dart';

class TextReaderPage extends StatefulWidget {
  final Book book;

  const TextReaderPage({super.key, required this.book});

  @override
  State<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends State<TextReaderPage> {
  late bool _dark;

  @override
  void initState() {
    super.initState();
    _dark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _toggleDark() => setState(() => _dark = !_dark);

  @override
  Widget build(BuildContext context) {
    final allSegments = widget.book.pages.expand((p) => p.segments).toList();

    final bgColor =
        _dark ? Colors.black : Theme.of(context).scaffoldBackgroundColor;
    final textColor = _dark ? const Color(0xFFD7D7D7) : Colors.black87;
    final appBarBg = _dark ? Colors.black : null;
    final appBarFg = _dark ? const Color(0xFFD7D7D7) : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        centerTitle: true,
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon:
                Icon(_dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: _dark ? '切换日间' : '切换夜间',
            onPressed: _toggleDark,
          ),
          if (widget.book.estimatedMinutes != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '约 ${widget.book.estimatedMinutes} 分钟',
                  style: TextStyle(color: appBarFg),
                ),
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
            style: TextStyle(fontSize: 20, height: 1.9, color: textColor),
          ),
        ),
      ),
    );
  }
}
