import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/screens/clients/clients_screen.dart';

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
      child: const MaterialApp(home: Scaffold(body: ClientsScreen())),
    );
  }

  testWidgets('shows empty state when no clients exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('No clients found'), findsOneWidget);
  });

  testWidgets('displays client name and email', (WidgetTester tester) async {
    await db.into(db.clients).insert(ClientsCompanion.insert(
          name: 'Acme Corp',
          email: const Value('acme@example.com'),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.text('acme@example.com'), findsOneWidget);
  });

  testWidgets('shows "No email" for client without email',
      (WidgetTester tester) async {
    await db.into(db.clients).insert(ClientsCompanion.insert(name: 'NoEmail'));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('No email'), findsOneWidget);
  });

  testWidgets('displays client currency', (WidgetTester tester) async {
    await db.into(db.clients).insert(ClientsCompanion.insert(
          name: 'Euro Client',
          currency: const Value('EUR'),
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('EUR'), findsOneWidget);
  });

  testWidgets('displays multiple clients', (WidgetTester tester) async {
    await db.into(db.clients).insert(ClientsCompanion.insert(name: 'Alpha'));
    await db.into(db.clients).insert(ClientsCompanion.insert(name: 'Beta'));
    await db.into(db.clients).insert(ClientsCompanion.insert(name: 'Gamma'));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('has a floating action button', (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('reactively updates when a client is added',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('No clients found'), findsOneWidget);

    await db.into(db.clients).insert(ClientsCompanion.insert(name: 'New'));
    await tester.pumpAndSettle();

    expect(find.text('New'), findsOneWidget);
    expect(find.textContaining('No clients found'), findsNothing);
  });
}
