import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/time_tracker/time_tracker_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildScreen() {
    return Provider<AppDatabase>.value(
      value: db,
      child: const MaterialApp(home: Scaffold(body: TimeTrackerScreen())),
    );
  }

  Future<int> seedClientAndProject() async {
    final cid = await db
        .into(db.clients)
        .insert(ClientsCompanion.insert(name: 'Client'));
    return db.into(db.projects).insert(ProjectsCompanion.insert(
          clientId: cid,
          name: 'Project',
          hourlyRate: 100.0,
        ));
  }

  testWidgets('shows "No active timer" when nothing is running',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('No active timer'), findsOneWidget);
  });

  testWidgets('shows "No time entries yet." when empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('No time entries yet.'), findsOneWidget);
  });

  testWidgets('displays a completed time entry', (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: pid,
          description: 'API work',
          startTime: DateTime(2024, 3, 1, 9, 0),
          endTime: Value(DateTime(2024, 3, 1, 11, 0)),
          category: 'Development',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('API work'), findsOneWidget);
    expect(find.textContaining('Development'), findsOneWidget);
  });

  testWidgets('shows active timer card for entry with null endTime',
      (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: pid,
          description: 'In progress',
          startTime: DateTime.now().subtract(const Duration(minutes: 30)),
          category: 'Coding',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('In progress'), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle), findsOneWidget);
  });

  testWidgets('has a floating action button', (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('shows Recent Entries header', (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Recent Entries'), findsOneWidget);
  });

  testWidgets('shows weekly total label', (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Week:'), findsOneWidget);
  });

  testWidgets('billed entry has green tinted card',
      (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: pid,
          description: 'Billed task',
          startTime: DateTime(2024, 3, 1, 9, 0),
          endTime: Value(DateTime(2024, 3, 1, 10, 0)),
          category: 'Dev',
          isBilled: const Value(true),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Billed task'), findsOneWidget);
    final card = tester.widget<Card>(find.ancestor(
      of: find.text('Billed task'),
      matching: find.byType(Card),
    ).first);
    expect(card.color, Colors.green.withAlpha(38));
  });

  testWidgets('unbilled entry has red tinted card',
      (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: pid,
          description: 'Unbilled task',
          startTime: DateTime(2024, 3, 1, 9, 0),
          endTime: Value(DateTime(2024, 3, 1, 10, 0)),
          category: 'Dev',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(find.ancestor(
      of: find.text('Unbilled task'),
      matching: find.byType(Card),
    ).first);
    expect(card.color, Colors.red.withAlpha(38));
  });

  testWidgets('displays multiple entries', (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    for (var i = 1; i <= 3; i++) {
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            projectId: pid,
            description: 'Task $i',
            startTime: DateTime(2024, 3, i, 9, 0),
            endTime: Value(DateTime(2024, 3, i, 10, 0)),
            category: 'Dev',
          ));
    }

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Task 3'), findsOneWidget);
  });

  testWidgets('each entry has an isLogged switch',
      (WidgetTester tester) async {
    final pid = await seedClientAndProject();
    await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: pid,
          description: 'Switchable',
          startTime: DateTime(2024, 3, 1, 9, 0),
          endTime: Value(DateTime(2024, 3, 1, 10, 0)),
          category: 'Dev',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsOneWidget);
  });
}
