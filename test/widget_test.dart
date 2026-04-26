import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/main.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapWithProvider(Widget child) {
    return Provider<AppDatabase>.value(
      value: db,
      child: child,
    );
  }

  testWidgets('MyApp renders MaterialApp with correct title',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));

    final materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Time Tracker');
  });

  testWidgets('MyApp uses dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));

    final materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.brightness, Brightness.dark);
  });

  testWidgets('MyApp hides debug banner', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));

    final materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.debugShowCheckedModeBanner, false);
  });

  testWidgets('MainScreen shows bottom navigation bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('Bottom nav has all expected tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Default screen shows Tasks To-Do in app bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Tasks To-Do'), findsOneWidget);
  });

  testWidgets('Tapping Clients tab switches to Clients screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(find.text('Clients'), findsWidgets);
  });

  testWidgets('Tapping Tracker tab switches to Time Tracker screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();

    expect(find.text('Time Tracker'), findsOneWidget);
  });

  testWidgets('Tapping Reports tab switches to Reports screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProvider(const MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsOneWidget);
  });
}
