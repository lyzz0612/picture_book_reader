import 'page.dart';

/// 阅读模式
enum BookMode {
  textOnly, // 文字版
  pictureBook; // 绘本版

  static BookMode fromString(String s) {
    switch (s) {
      case 'textOnly':
        return BookMode.textOnly;
      case 'pictureBook':
        return BookMode.pictureBook;
      default:
        throw ArgumentError('Unknown BookMode: $s');
    }
  }
}

/// 绘本
class Book {
  final String id; // 唯一标识
  final String title; // 绘本标题
  final String coverPath; // 封面图片路径（assets 内相对路径，文字版可为空）
  final BookMode mode; // 模式：textOnly / pictureBook
  final List<Page> pages; // 页面列表
  final int? estimatedMinutes; // 预计阅读时长（分钟）

  const Book({
    required this.id,
    required this.title,
    required this.coverPath,
    required this.mode,
    required this.pages,
    this.estimatedMinutes,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      coverPath: (json['coverPath'] as String?) ?? '',
      mode: BookMode.fromString(json['mode'] as String),
      pages: (json['pages'] as List)
          .map((e) => Page.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: json['estimatedMinutes'] as int?,
    );
  }
}
