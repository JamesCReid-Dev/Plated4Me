/// Application entry point. Initializes the Isar database before launching the app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/navigation/app_router.dart';
import 'package:plated4me/presentation/theme/app_theme.dart';

/// Global Isar instance, accessible for testing.
/// Tests can use [createIsarInstance] directly with an in-memory directory.
Isar? _isarInstance;

/// Returns the globally-initialized Isar instance.
/// Throws if called before [initDatabase] completes.
Isar get isar {
  if (_isarInstance == null) {
    throw StateError('Isar not initialized — call initDatabase() before accessing');
  }
  return _isarInstance!;
}

/// Initializes the Isar database with all entity collections.
///
/// Called from [main] before [runApp]. Creates the app directory and opens
/// the database with [RestaurantSchema], [VisitSchema], and [UserPreferencesSchema].
Future<void> initDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  _isarInstance = await Isar.open(
    [RestaurantSchema, VisitSchema, UserPreferencesSchema],
    directory: dir.path,
    inspector: true, // Enable schema inspection in debug mode
  );
}

/// Creates an isolated Isar instance for testing.
///
/// By default uses an in-memory database (`':memory:'`) for fast,
/// isolated unit tests. Pass a [directory] to use file-based storage.
Future<Isar> createIsarInstance({String? directory}) async {
  return await Isar.open(
    [RestaurantSchema, VisitSchema, UserPreferencesSchema],
    directory: directory ?? ':memory:',
  );
}

void main() async {
  // Ensure Flutter bindings are initialized before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database before launching the app (AC-2, AC-4)
  await initDatabase();

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
