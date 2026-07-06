import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book.dart';

/// 书架索引条目（来自 assets/books/index.json）
class BookIndexEntry {
  final String id;
  final String title;
  final BookMode mode;
  final String coverPath; // 相对 assets 的封面路径（空字符串表示无封面，用占位图）
  final String metaPath; // 相对 assets 的 meta.json 路径

  const BookIndexEntry({
    required this.id,
    required this.title,
    required this.mode,
    required this.coverPath,
    required this.metaPath,
  });

  factory BookIndexEntry.fromJson(Map<String, dynamic> json) {
    return BookIndexEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      mode: BookMode.fromString(json['mode'] as String),
      coverPath: (json['coverPath'] as String?) ?? '',
      metaPath: json['metaPath'] as String,
    );
  }
}

/// 内置绘本加载服务
class BookService {
  BookService._();
  static final BookService instance = BookService._();

  static const String _indexPath = 'assets/books/index.json';

  /// 读取书架索引
  Future<List<BookIndexEntry>> loadIndex() async {
    final raw = await rootBundle.loadString(_indexPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['books'] as List)
        .map((e) => BookIndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// 读取某本绘本完整数据
  Future<Book> loadBook(String metaPath) async {
    final raw = await rootBundle.loadString('assets/$metaPath');
    return Book.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
