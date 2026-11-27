import 'package:flutter/material.dart';

import 'screens/diary_feed_screen.dart';
import 'services/diary_services.dart';

class PhotoDiaryApp extends StatelessWidget {
  const PhotoDiaryApp({super.key, required this.services});

  final DiaryServices services;

  static const _seed = Color(0xFF1B6B5A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Narxoz Photo Diary',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: DiaryFeedScreen(services: services),
    );
  }
}
