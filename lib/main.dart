// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/main_screen.dart';
import 'package:time_tracker/services/barcode_lookup_service.dart';
import 'package:time_tracker/services/item_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Existing drift database — consumed by the core app.
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        // Barcode feature: file-backed item repository. Registered here so
        // every screen consumes it via Provider.of (matches the AppDatabase
        // pattern already used elsewhere).
        Provider<ItemRepository>(
          create: (_) => ItemRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        // Lookup service depends on the repository, so we wire it with
        // ProxyProvider to let Provider own its lifecycle.
        ProxyProvider<ItemRepository, BarcodeLookupService>(
          update: (_, repo, previous) =>
              previous ?? BarcodeLookupService(repository: repo),
          dispose: (_, svc) => svc.dispose(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color.fromARGB(255, 28, 25, 38),
        cardColor: const Color.fromARGB(255, 0, 0, 0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color.fromARGB(255, 28, 25, 38),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
