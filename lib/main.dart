import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: Plated4MeApp()));
}

/// Root application widget. Wraps everything in a [ProviderScope] for Riverpod DI.
class Plated4MeApp extends ConsumerWidget {
  const Plated4MeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Plated4Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppRouter(),
    );
  }
}
