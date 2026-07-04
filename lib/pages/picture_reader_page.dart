import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/page.dart' as model;
import '../widgets/text_segment_view.dart';

/// 绘本版阅读页：一图多文状态机
///
/// 状态：pageIndex（当前页）+ segmentIndex（当前文字段）
/// 交互：点击屏幕右侧 / 右滑 → 下一段（同图内）或下一张图
///       点击屏幕左侧 / 左滑 → 上一段（同图内）或上一张图
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

  void _next() {
    if (!_isLastSegment) {
      setState(() => _segmentIndex++);
    } else if (!_isLastPage) {
      setState(() {
        _pageIndex++;
        _segmentIndex = 0;
      });
    } else {
      _finish();
    }
  }

  void _prev() {
    if (!_isFirstSegment) {
      setState(() => _segmentIndex--);
    } else if (!_isFirstPage) {
      setState(() {
        _pageIndex--;
        _segmentIndex = widget.book.pages[_pageIndex].segments.length - 1;
      });
    }
  }

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('阅读完成')),
    );
    Navigator.pop(context);
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final mid = MediaQuery.of(context).size.width / 2;
          if (details.localPosition.dx > mid) {
            _next();
          } else {
            _prev();
          }
        },
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -100) {
            _next();
          } else if (v > 100) {
            _prev();
          }
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 图片层
        if (_currentPage.imagePath != null)
          Image.asset(
            'assets/${_currentPage.imagePath}',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade300),
          )
        else
          Container(color: Colors.grey.shade200),

        // 渐变遮罩 + 文字段
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _currentPage.segments.length; i++)
                  TextSegmentView(
                    segment: _currentPage.segments[i],
                    state: i == _segmentIndex
                        ? SegmentState.current
                        : i < _segmentIndex
                            ? SegmentState.read
                            : SegmentState.unread,
                  ),
                const SizedBox(height: 8),
                Text(
                  '点击右侧下一段 · 点击左侧上一段',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
