import 'package:flutter/material.dart';
import '../core/router.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/book_card.dart';

/// 书架列表页（按模式过滤）
class BookshelfPage extends StatefulWidget {
  final BookMode mode;

  const BookshelfPage({super.key, required this.mode});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  List<BookIndexEntry>? _entries;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await BookService.instance.loadIndex();
      if (!mounted) return;
      setState(() {
        _entries = all.where((e) => e.mode == widget.mode).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == BookMode.textOnly ? '文字版' : '绘本版';
    return Scaffold(
      appBar: AppBar(title: Text('$title · 书架')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('加载失败: $_error'));
    }
    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries!.isEmpty) {
      return const Center(child: Text('暂无书籍'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _entries!.length,
      itemBuilder: (_, i) {
        final e = _entries![i];
        return BookCard(
          title: e.title,
          coverPath: null,
          onTap: () => _openBook(e),
        );
      },
    );
  }

  Future<void> _openBook(BookIndexEntry e) async {
    try {
      final book = await BookService.instance.loadBook(e.metaPath);
      if (!mounted) return;
      final route = e.mode == BookMode.textOnly
          ? AppRouter.textReader
          : AppRouter.pictureReader;
      Navigator.pushNamed(context, route, arguments: book);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('打开失败: $err')));
    }
  }
}
