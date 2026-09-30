import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'screens/main_layout_screen.dart';

void main() {
  runApp(const ProviderScope(child: ScaleBuddyApp()));
}

/// Wurzel-Widget der ScaleBuddy-App.
class ScaleBuddyApp extends StatelessWidget {
  const ScaleBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayoutScreen(),
    );
  }
}
