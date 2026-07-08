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

/// 文字版故事分类（仅 textOnly 模式使用）
enum BookCategory {
  animal, // 动物拟人
  chineseFable, // 国产寓言
  foreignFable, // 国外寓言
  idiom; // 成语故事

  static BookCategory fromString(String s) {
    switch (s) {
      case 'animal':
        return BookCategory.animal;
      case 'chineseFable':
        return BookCategory.chineseFable;
      case 'foreignFable':
        return BookCategory.foreignFable;
      case 'idiom':
        return BookCategory.idiom;
      default:
        throw ArgumentError('Unknown BookCategory: $s');
    }
  }

  /// 中文展示名
  String get label => switch (this) {
        BookCategory.animal => '动物拟人',
        BookCategory.chineseFable => '国产寓言',
        BookCategory.foreignFable => '国外寓言',
        BookCategory.idiom => '成语故事',
      };
}

/// 绘本
class Book {
  final String id; // 唯一标识
  final String title; // 绘本标题
  final String coverPath; // 封面图片路径（assets 内相对路径，文字版可为空）
  final BookMode mode; // 模式：textOnly / pictureBook
  final List<Page> pages; // 页面列表
  final int? estimatedMinutes; // 预计阅读时长（分钟）
  final BookCategory? category; // 分类（仅文字版有意义）

  const Book({
    required this.id,
    required this.title,
    required this.coverPath,
    required this.mode,
    required this.pages,
    this.estimatedMinutes,
    this.category,
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
      category: (json['category'] as String?) != null
          ? BookCategory.fromString(json['category'] as String)
          : null,
    );
  }
}
