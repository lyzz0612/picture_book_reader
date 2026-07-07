import 'package:flutter/material.dart';
import '../models/book.dart';
import '../pages/bookshelf_page.dart';
import '../pages/mode_select_page.dart';
import '../pages/picture_reader_page.dart';
import '../pages/settings_page.dart';
import '../pages/text_reader_page.dart';

/// 路由定义（使用 Flutter 内置 Navigator，不引入路由框架）
class AppRouter {
  AppRouter._();

  static const String modeSelect = '/';
  static const String bookshelf = '/bookshelf';
  static const String textReader = '/text-reader';
  static const String pictureReader = '/picture-reader';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case modeSelect:
        return MaterialPageRoute(builder: (_) => const ModeSelectPage());
      case bookshelf:
        final mode = routeSettings.arguments as BookMode;
        return MaterialPageRoute(builder: (_) => BookshelfPage(mode: mode));
      case textReader:
        final book = routeSettings.arguments as Book;
        return MaterialPageRoute(builder: (_) => TextReaderPage(book: book));
      case pictureReader:
        final book = routeSettings.arguments as Book;
        return MaterialPageRoute(builder: (_) => PictureReaderPage(book: book));
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const ModeSelectPage());
    }
  }
}
