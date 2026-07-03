import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/update_service.dart';

class PictureBookApp extends StatefulWidget {
  const PictureBookApp({super.key});

  @override
  State<PictureBookApp> createState() => _PictureBookAppState();
}

class _PictureBookAppState extends State<PictureBookApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // 注入 navigatorKey 供更新弹窗使用
    UpdateService.instance.setNavigatorKey(_navigatorKey);
    // 启动时静默检查更新
    UpdateService.instance.checkForUpdateOnLaunch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '绘本阅读',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      navigatorKey: _navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.modeSelect,
    );
  }
}
