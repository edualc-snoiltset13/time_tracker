import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/home_screen.dart';

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
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
  }

  Future<int> seedProject() async {
    final cid = await db
        .into(db.clients)
        .insert(ClientsCompanion.insert(name: 'Client'));
    return db.into(db.projects).insert(ProjectsCompanion.insert(
          clientId: cid,
          name: 'Project',
          hourlyRate: 100.0,
        ));
  }

  testWidgets('shows empty state when no todos', (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('No tasks found'), findsOneWidget);
  });

  testWidgets('displays a todo with title and project name',
      (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'Implement login',
          projectId: pid,
          category: 'Feature',
          deadline: DateTime(2024, 6, 15),
          priority: 'P1',
          startTime: DateTime(2024, 6, 1),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Implement login'), findsOneWidget);
    expect(find.textContaining('Project'), findsOneWidget);
  });

  testWidgets('shows priority chip with correct text',
      (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'Urgent fix',
          projectId: pid,
          category: 'Bug',
          deadline: DateTime(2024, 6, 15),
          priority: 'P1',
          startTime: DateTime(2024, 6, 1),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
  });

  testWidgets('completed todo has strikethrough decoration',
      (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'Done task',
          projectId: pid,
          category: 'Task',
          deadline: DateTime(2024, 6, 15),
          priority: 'P3',
          startTime: DateTime(2024, 6, 1),
          isCompleted: const Value(true),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Done task'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('uncompleted todo has no strikethrough',
      (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'Open task',
          projectId: pid,
          category: 'Task',
          deadline: DateTime(2024, 6, 15),
          priority: 'P2',
          startTime: DateTime(2024, 6, 1),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Open task'));
    expect(textWidget.style?.decoration, TextDecoration.none);
  });

  testWidgets('each todo has a checkbox', (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'With checkbox',
          projectId: pid,
          category: 'Task',
          deadline: DateTime(2024, 6, 15),
          priority: 'P2',
          startTime: DateTime(2024, 6, 1),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('each todo has a play button to start timer',
      (WidgetTester tester) async {
    final pid = await seedProject();
    await db.into(db.todos).insert(TodosCompanion.insert(
          title: 'Timeable',
          projectId: pid,
          category: 'Task',
          deadline: DateTime(2024, 6, 15),
          priority: 'P2',
          startTime: DateTime(2024, 6, 1),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('has Clear Completed and Add FABs',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Clear Completed'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('displays multiple todos', (WidgetTester tester) async {
    final pid = await seedProject();
    for (final title in ['Task A', 'Task B', 'Task C']) {
      await db.into(db.todos).insert(TodosCompanion.insert(
            title: title,
            projectId: pid,
            category: 'Task',
            deadline: DateTime(2024, 6, 15),
            priority: 'P2',
            startTime: DateTime(2024, 6, 1),
          ));
    }

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Task A'), findsOneWidget);
    expect(find.text('Task B'), findsOneWidget);
    expect(find.text('Task C'), findsOneWidget);
  });
}
