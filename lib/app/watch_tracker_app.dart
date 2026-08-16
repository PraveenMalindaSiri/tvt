import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/watch_tracker/ui/pages/watch_tracker_page.dart';

class WatchTrackerApp extends StatelessWidget {
  const WatchTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TvT',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const WatchTrackerPage(),
    );
  }
}
