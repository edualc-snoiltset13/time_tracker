// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/main_screen.dart'; // Import the main screen with the navigation bar
import 'package:time_tracker/services/idle_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (context) => AppDatabase(),
          dispose: (context, db) => db.close(),
        ),
        Provider<IdleService>(
          create: (context) => IdleService(),
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
    final idleService = Provider.of<IdleService>(context, listen: false);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => idleService.recordActivity(),
      onPointerMove: (_) => idleService.recordActivity(),
      onPointerHover: (_) => idleService.recordActivity(),
      onPointerSignal: (_) => idleService.recordActivity(),
      child: MaterialApp(
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
            backgroundColor: Color.fromARGB(255, 28, 25, 38)
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple,
          ),
        ),
        // Use MainScreen as the home widget
        home: const MainScreen(),
      ),
    );
  }
}
