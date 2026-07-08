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

  /// 当前选中的分类（null = 全部）。仅文字版使用。
  BookCategory? _selectedCategory;

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

  /// 文字版下当前可用的分类（依据实际数据动态生成）
  List<BookCategory> get _availableCategories {
    final entries = _entries;
    if (entries == null) return const [];
    final set = <BookCategory>{};
    for (final e in entries) {
      final c = e.category;
      if (c != null) set.add(c);
    }
    // 固定顺序展示
    return [
      BookCategory.animal,
      BookCategory.chineseFable,
      BookCategory.foreignFable,
      BookCategory.idiom,
      BookCategory.lifeHabit,
      BookCategory.sceneExperience,
    ].where((c) => set.contains(c)).toList();
  }

  List<BookIndexEntry> get _filteredEntries {
    final entries = _entries;
    if (entries == null) return const [];
    if (_selectedCategory == null) return entries;
    return entries
        .where((e) => e.category == _selectedCategory)
        .toList();
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
    final list = _filteredEntries;
    final showCategoryBar =
        widget.mode == BookMode.textOnly && _availableCategories.isNotEmpty;

    return Column(
      children: [
        if (showCategoryBar) _buildCategoryBar(),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('该分类暂无书籍'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    return BookCard(
                      title: e.title,
                      coverPath: e.coverPath.isEmpty ? null : e.coverPath,
                      estimatedMinutes: e.estimatedMinutes,
                      onTap: () => _openBook(e),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 分类筛选条
  Widget _buildCategoryBar() {
    final cats = _availableCategories;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _categoryChip(label: '全部', selected: _selectedCategory == null,
                onTap: () {
              setState(() => _selectedCategory = null);
            }),
            for (final c in cats) ...[
              const SizedBox(width: 8),
              _categoryChip(
                label: c.label,
                selected: _selectedCategory == c,
                onTap: () => setState(() => _selectedCategory = c),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.black54,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
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
