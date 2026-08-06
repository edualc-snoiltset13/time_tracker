// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/main_screen.dart'; // Import the main screen with the navigation bar

void main() {
  runApp(
    Provider<AppDatabase>(
      create: (context) => AppDatabase(),
      dispose: (context, db) => db.close(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF6B4BA3), // Deep spiritual purple
        scaffoldBackgroundColor: const Color(0xFF0F0F1E), // Deep dark background
        cardColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B7FBA),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF0F0F1E),
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9B7FBA),
            letterSpacing: 1.2,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9B7FBA),
        ),
      ),
      home: const MainScreen(),
    );
  }
}