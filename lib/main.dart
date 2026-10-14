import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'screens/main_layout_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ScaleBuddyApp()));
}

/// Wurzel-Widget der ScaleBuddy-App.
class ScaleBuddyApp extends StatelessWidget {
  final Locale? locale;

  const ScaleBuddyApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('de'),
      home: const MainLayoutScreen(),
    );
  }
}
