import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/page.dart' as model;
import '../widgets/text_segment_view.dart';

class PictureReaderPage extends StatefulWidget {
  final Book book;

  const PictureReaderPage({super.key, required this.book});

  @override
  State<PictureReaderPage> createState() => _PictureReaderPageState();
}

class _PictureReaderPageState extends State<PictureReaderPage> {
  int _pageIndex = 0;
  int _segmentIndex = 0;

  model.Page get _currentPage => widget.book.pages[_pageIndex];
  bool get _isFirstPage => _pageIndex == 0;
  bool get _isLastPage => _pageIndex == widget.book.pages.length - 1;
  bool get _isFirstSegment => _segmentIndex == 0;
  bool get _isLastSegment => _segmentIndex == _currentPage.segments.length - 1;

  void _nextSegment() {
    if (!_isLastSegment) setState(() => _segmentIndex++);
  }

  void _prevSegment() {
    if (!_isFirstSegment) setState(() => _segmentIndex--);
  }

  void _nextPage() {
    if (!_isLastPage) {
      setState(() {
        _pageIndex++;
        _segmentIndex = 0;
      });
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (!_isFirstPage) {
      setState(() {
        _pageIndex--;
        _segmentIndex = 0;
      });
    }
  }

  void _finish() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('阅读完成'),
        content: Text('《${widget.book.title}》已经读完啦'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回书架'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_pageIndex + 1}/${widget.book.pages.length}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(builder: (context, constraints) {
      final maxTextHeight = constraints.maxHeight * 0.45;
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -100) {
                _nextPage();
              } else if (v > 100) {
                _prevPage();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_currentPage.id),
                child: _currentPage.imagePath != null
                    ? Image.asset(
                        'assets/${_currentPage.imagePath}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade300),
                      )
                    : Container(color: Colors.grey.shade200),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -100) {
                  _nextSegment();
                } else if (v > 100) {
                  _prevSegment();
                }
              },
              child: Container(
                constraints: BoxConstraints(maxHeight: maxTextHeight),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: TextSegmentView(
                          key: ValueKey(
                              '${_currentPage.id}-$_segmentIndex'),
                          segment: _currentPage.segments[_segmentIndex],
                          state: SegmentState.current,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '文字 ${_segmentIndex + 1}/${_currentPage.segments.length} · 图片 ${_pageIndex + 1}/${widget.book.pages.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (_currentPage.segments.length > 1)
                            Icon(
                              Icons.swap_horiz,
                              size: 14,
                              color: Colors.white.withOpacity(0.4),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
