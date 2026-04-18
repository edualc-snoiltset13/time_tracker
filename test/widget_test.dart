import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/main.dart';

void main() {
  testWidgets('MyApp builds without error', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        dispose: (_, db) => db.close(),
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    await db.close();
  });
}
