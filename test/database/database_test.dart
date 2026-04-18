import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('schemaVersion is 3', () {
      expect(db.schemaVersion, 3);
    });
  });

  group('Clients', () {
    test('insert and read back a client', () async {
      final id = await db.into(db.clients).insert(
            ClientsCompanion.insert(
              name: 'Acme Corp',
              email: const Value('billing@acme.test'),
              address: const Value('1 Main St'),
            ),
          );

      final stored = await (db.select(db.clients)
            ..where((c) => c.id.equals(id)))
          .getSingle();

      expect(stored.name, 'Acme Corp');
      expect(stored.email, 'billing@acme.test');
      expect(stored.address, '1 Main St');
    });

    test('currency defaults to USD when omitted', () async {
      final id = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Default Currency Co'));

      final stored =
          await (db.select(db.clients)..where((c) => c.id.equals(id)))
              .getSingle();

      expect(stored.currency, 'USD');
    });

    test('optional fields can be left null', () async {
      final id = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'No Contact Info'));

      final stored =
          await (db.select(db.clients)..where((c) => c.id.equals(id)))
              .getSingle();

      expect(stored.email, isNull);
      expect(stored.address, isNull);
    });

    test('update mutates the targeted row only', () async {
      final firstId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'First'));
      final secondId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Second'));

      await (db.update(db.clients)..where((c) => c.id.equals(firstId)))
          .write(const ClientsCompanion(name: Value('First Renamed')));

      final first =
          await (db.select(db.clients)..where((c) => c.id.equals(firstId)))
              .getSingle();
      final second =
          await (db.select(db.clients)..where((c) => c.id.equals(secondId)))
              .getSingle();

      expect(first.name, 'First Renamed');
      expect(second.name, 'Second');
    });

    test('delete removes the row', () async {
      final id = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Soon Gone'));

      final deletedCount =
          await (db.delete(db.clients)..where((c) => c.id.equals(id))).go();

      expect(deletedCount, 1);
      final remaining = await db.select(db.clients).get();
      expect(remaining, isEmpty);
    });
  });

  group('Projects', () {
    test('insert project referencing a client', () async {
      final clientId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Client A'));

      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
              clientId: clientId,
              name: 'Website Redesign',
              hourlyRate: 125.0,
            ),
          );

      final project = await (db.select(db.projects)
            ..where((p) => p.id.equals(projectId)))
          .getSingle();

      expect(project.clientId, clientId);
      expect(project.name, 'Website Redesign');
      expect(project.hourlyRate, 125.0);
      expect(project.status, 'Active');
      expect(project.monthlyTimeLimit, isNull);
    });
  });

  group('TimeEntries', () {
    test('defaults isBillable=true, isBilled=false, isLogged=false', () async {
      final clientId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'C'));
      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
              clientId: clientId,
              name: 'P',
              hourlyRate: 50.0,
            ),
          );

      final entryId = await db.into(db.timeEntries).insert(
            TimeEntriesCompanion.insert(
              projectId: projectId,
              description: 'Initial work',
              startTime: DateTime(2026, 1, 1, 9),
              category: 'Development',
            ),
          );

      final entry = await (db.select(db.timeEntries)
            ..where((t) => t.id.equals(entryId)))
          .getSingle();

      expect(entry.isBillable, isTrue);
      expect(entry.isBilled, isFalse);
      expect(entry.isLogged, isFalse);
      expect(entry.endTime, isNull);
    });

    test('persists endTime and billing flag overrides', () async {
      final clientId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'C'));
      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
              clientId: clientId,
              name: 'P',
              hourlyRate: 50.0,
            ),
          );

      final start = DateTime(2026, 1, 1, 9);
      final end = DateTime(2026, 1, 1, 11, 30);

      final entryId = await db.into(db.timeEntries).insert(
            TimeEntriesCompanion.insert(
              projectId: projectId,
              description: 'Completed session',
              startTime: start,
              endTime: Value(end),
              category: 'Development',
              isBillable: const Value(false),
              isBilled: const Value(true),
              isLogged: const Value(true),
            ),
          );

      final entry = await (db.select(db.timeEntries)
            ..where((t) => t.id.equals(entryId)))
          .getSingle();

      expect(entry.startTime, start);
      expect(entry.endTime, end);
      expect(entry.isBillable, isFalse);
      expect(entry.isBilled, isTrue);
      expect(entry.isLogged, isTrue);
    });
  });

  group('Expenses', () {
    test('project and client foreign keys are optional', () async {
      final expenseId = await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              description: 'Standalone expense',
              category: 'Office',
              amount: 42.50,
              date: DateTime(2026, 2, 1),
            ),
          );

      final expense = await (db.select(db.expenses)
            ..where((e) => e.id.equals(expenseId)))
          .getSingle();

      expect(expense.projectId, isNull);
      expect(expense.clientId, isNull);
      expect(expense.isBilled, isFalse);
      expect(expense.distance, isNull);
      expect(expense.costPerUnit, isNull);
    });

    test('stores mileage fields when provided', () async {
      final expenseId = await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              description: 'Client visit',
              category: 'Travel',
              amount: 57.75,
              date: DateTime(2026, 2, 1),
              distance: const Value(150.0),
              costPerUnit: const Value(0.385),
            ),
          );

      final expense = await (db.select(db.expenses)
            ..where((e) => e.id.equals(expenseId)))
          .getSingle();

      expect(expense.distance, 150.0);
      expect(expense.costPerUnit, closeTo(0.385, 1e-9));
    });
  });

  group('Invoices', () {
    test('lineItemsJson round-trips through LineItem helpers', () async {
      final clientId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Invoice Client'));

      final items = [
        LineItem(description: 'Work A', quantity: 10, unitPrice: 100),
        LineItem(description: 'Work B', quantity: 2.5, unitPrice: 125),
      ];

      final invoiceId = await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceIdString: 'INV-0001',
              clientId: clientId,
              issueDate: DateTime(2026, 3, 1),
              dueDate: DateTime(2026, 3, 31),
              totalAmount: 1312.5,
              status: 'Draft',
              lineItemsJson: Value(lineItemsToJson(items)),
            ),
          );

      final invoice = await (db.select(db.invoices)
            ..where((i) => i.id.equals(invoiceId)))
          .getSingle();

      expect(invoice.invoiceIdString, 'INV-0001');
      expect(invoice.totalAmount, 1312.5);
      expect(invoice.notes, isNull);

      final restored = lineItemsFromJson(invoice.lineItemsJson!);
      expect(restored.length, 2);
      expect(restored[0].description, 'Work A');
      expect(restored[1].total, 312.5);
    });
  });

  group('Todos', () {
    test('defaults isCompleted to false', () async {
      final clientId = await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'C'));
      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
              clientId: clientId,
              name: 'P',
              hourlyRate: 80.0,
            ),
          );

      final todoId = await db.into(db.todos).insert(
            TodosCompanion.insert(
              title: 'Ship it',
              projectId: projectId,
              category: 'Launch',
              deadline: DateTime(2026, 4, 1),
              priority: 'High',
              startTime: DateTime(2026, 3, 20),
            ),
          );

      final todo = await (db.select(db.todos)
            ..where((t) => t.id.equals(todoId)))
          .getSingle();

      expect(todo.isCompleted, isFalse);
      expect(todo.estimatedHours, isNull);
      expect(todo.description, isNull);
    });
  });

  group('CompanySettings', () {
    test('showLetterhead defaults to true and logoPath is nullable', () async {
      final id = await db.into(db.companySettings).insert(
            CompanySettingsCompanion.insert(
              companyName: 'My Co',
              companyAddress: '123 Road',
            ),
          );

      final settings = await (db.select(db.companySettings)
            ..where((s) => s.id.equals(id)))
          .getSingle();

      expect(settings.showLetterhead, isTrue);
      expect(settings.logoPath, isNull);
    });
  });
}
