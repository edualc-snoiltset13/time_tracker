// test/database/database_test.dart
//
// Integration tests for AppDatabase using an in-memory SQLite database.
// These verify CRUD operations, default values, foreign key constraints,
// and cascade delete behavior.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/database/database.dart';

/// Creates an in-memory AppDatabase for testing (no filesystem needed).
AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('Clients table', () {
    test('can insert and retrieve a client', () async {
      final id = await db.into(db.clients).insert(ClientsCompanion.insert(
            name: 'Acme Corp',
          ));

      final client =
          await (db.select(db.clients)..where((c) => c.id.equals(id)))
              .getSingle();

      expect(client.name, 'Acme Corp');
      expect(client.email, isNull);
      expect(client.address, isNull);
    });

    test('defaults currency to USD', () async {
      final id = await db.into(db.clients).insert(ClientsCompanion.insert(
            name: 'Test Client',
          ));

      final client =
          await (db.select(db.clients)..where((c) => c.id.equals(id)))
              .getSingle();

      expect(client.currency, 'USD');
    });

    test('can store optional email and address', () async {
      final id = await db.into(db.clients).insert(ClientsCompanion.insert(
            name: 'Full Client',
            email: const Value('test@example.com'),
            address: const Value('123 Main St'),
            currency: const Value('EUR'),
          ));

      final client =
          await (db.select(db.clients)..where((c) => c.id.equals(id)))
              .getSingle();

      expect(client.email, 'test@example.com');
      expect(client.address, '123 Main St');
      expect(client.currency, 'EUR');
    });
  });

  group('Projects table', () {
    late int clientId;

    setUp(() async {
      clientId = await db.into(db.clients).insert(ClientsCompanion.insert(
            name: 'Test Client',
          ));
    });

    test('can insert a project linked to a client', () async {
      final id = await db.into(db.projects).insert(ProjectsCompanion.insert(
            name: 'Website Redesign',
            clientId: clientId,
            hourlyRate: 150.0,
          ));

      final project =
          await (db.select(db.projects)..where((p) => p.id.equals(id)))
              .getSingle();

      expect(project.name, 'Website Redesign');
      expect(project.clientId, clientId);
      expect(project.hourlyRate, 150.0);
    });

    test('defaults status to Active', () async {
      final id = await db.into(db.projects).insert(ProjectsCompanion.insert(
            name: 'New Project',
            clientId: clientId,
            hourlyRate: 100.0,
          ));

      final project =
          await (db.select(db.projects)..where((p) => p.id.equals(id)))
              .getSingle();

      expect(project.status, 'Active');
    });

    test('monthlyTimeLimit is nullable', () async {
      final id = await db.into(db.projects).insert(ProjectsCompanion.insert(
            name: 'Unlimited Project',
            clientId: clientId,
            hourlyRate: 80.0,
          ));

      final project =
          await (db.select(db.projects)..where((p) => p.id.equals(id)))
              .getSingle();

      expect(project.monthlyTimeLimit, isNull);
    });
  });

  group('TimeEntries table', () {
    late int projectId;

    setUp(() async {
      final clientId = await db.into(db.clients).insert(
            ClientsCompanion.insert(name: 'Client'),
          );
      projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
                name: 'Project', clientId: clientId, hourlyRate: 100.0),
          );
    });

    test('can insert a time entry with endTime null (active timer)', () async {
      final id =
          await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
                description: 'Working on feature',
                projectId: projectId,
                category: 'Client Operations',
                startTime: DateTime(2025, 3, 12, 9, 0),
              ));

      final entry =
          await (db.select(db.timeEntries)..where((t) => t.id.equals(id)))
              .getSingle();

      expect(entry.description, 'Working on feature');
      expect(entry.endTime, isNull);
    });

    test('defaults isBillable to true, isBilled to false, isLogged to false',
        () async {
      final id =
          await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
                description: 'Test',
                projectId: projectId,
                category: 'Test Management',
                startTime: DateTime(2025, 3, 12, 9, 0),
              ));

      final entry =
          await (db.select(db.timeEntries)..where((t) => t.id.equals(id)))
              .getSingle();

      expect(entry.isBillable, true);
      expect(entry.isBilled, false);
      expect(entry.isLogged, false);
    });

    test('can set endTime to complete a time entry', () async {
      final id =
          await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
                description: 'Completed task',
                projectId: projectId,
                category: 'Client Meetings',
                startTime: DateTime(2025, 3, 12, 9, 0),
              ));

      await (db.update(db.timeEntries)..where((t) => t.id.equals(id)))
          .write(TimeEntriesCompanion(
        endTime: Value(DateTime(2025, 3, 12, 10, 30)),
      ));

      final entry =
          await (db.select(db.timeEntries)..where((t) => t.id.equals(id)))
              .getSingle();

      expect(entry.endTime, DateTime(2025, 3, 12, 10, 30));
      final duration = entry.endTime!.difference(entry.startTime);
      expect(duration.inMinutes, 90);
    });
  });

  group('Expenses table', () {
    test('can insert an expense without project or client', () async {
      final id = await db.into(db.expenses).insert(ExpensesCompanion.insert(
            description: 'Office supplies',
            category: 'Other',
            amount: 42.50,
            date: DateTime(2025, 3, 10),
          ));

      final expense =
          await (db.select(db.expenses)..where((e) => e.id.equals(id)))
              .getSingle();

      expect(expense.description, 'Office supplies');
      expect(expense.amount, 42.50);
      expect(expense.projectId, isNull);
      expect(expense.clientId, isNull);
      expect(expense.isBilled, false);
    });

    test('supports mileage fields', () async {
      final id = await db.into(db.expenses).insert(ExpensesCompanion.insert(
            description: 'Client visit',
            category: 'Mileage',
            amount: 33.50,
            date: DateTime(2025, 3, 10),
            distance: const Value(50.0),
            costPerUnit: const Value(0.67),
          ));

      final expense =
          await (db.select(db.expenses)..where((e) => e.id.equals(id)))
              .getSingle();

      expect(expense.distance, 50.0);
      expect(expense.costPerUnit, 0.67);
    });
  });

  group('Cascade deletes', () {
    test('deleting a client cascades to its projects', () async {
      final clientId = await db.into(db.clients).insert(
            ClientsCompanion.insert(name: 'To Delete'),
          );
      await db.into(db.projects).insert(
            ProjectsCompanion.insert(
                name: 'Doomed Project', clientId: clientId, hourlyRate: 50.0),
          );

      // Verify project exists
      var projects = await db.select(db.projects).get();
      expect(projects.length, 1);

      // Delete client
      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      // Project should be gone
      projects = await db.select(db.projects).get();
      expect(projects, isEmpty);
    });

    test('deleting a client cascades through projects to time entries',
        () async {
      final clientId = await db.into(db.clients).insert(
            ClientsCompanion.insert(name: 'Client'),
          );
      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
                name: 'Project', clientId: clientId, hourlyRate: 100.0),
          );
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            description: 'Entry',
            projectId: projectId,
            category: 'Test Management',
            startTime: DateTime(2025, 3, 12, 9, 0),
          ));

      // Verify entry exists
      var entries = await db.select(db.timeEntries).get();
      expect(entries.length, 1);

      // Delete client -- should cascade to project and then time entry
      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      entries = await db.select(db.timeEntries).get();
      expect(entries, isEmpty);
    });

    test('deleting a project cascades to its time entries', () async {
      final clientId = await db.into(db.clients).insert(
            ClientsCompanion.insert(name: 'Client'),
          );
      final projectId = await db.into(db.projects).insert(
            ProjectsCompanion.insert(
                name: 'Project', clientId: clientId, hourlyRate: 100.0),
          );
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            description: 'Entry',
            projectId: projectId,
            category: 'Test Management',
            startTime: DateTime(2025, 3, 12, 9, 0),
          ));

      await (db.delete(db.projects)..where((p) => p.id.equals(projectId)))
          .go();

      final entries = await db.select(db.timeEntries).get();
      expect(entries, isEmpty);
    });
  });

  group('Invoices table', () {
    late int clientId;

    setUp(() async {
      clientId = await db.into(db.clients).insert(
            ClientsCompanion.insert(name: 'Invoice Client'),
          );
    });

    test('can insert and retrieve an invoice', () async {
      final id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
            invoiceIdString: 'INV-2025-03-001',
            clientId: clientId,
            issueDate: DateTime(2025, 3, 1),
            dueDate: DateTime(2025, 3, 31),
            totalAmount: 1500.0,
            status: 'Draft',
          ));

      final invoice =
          await (db.select(db.invoices)..where((i) => i.id.equals(id)))
              .getSingle();

      expect(invoice.invoiceIdString, 'INV-2025-03-001');
      expect(invoice.totalAmount, 1500.0);
      expect(invoice.status, 'Draft');
      expect(invoice.notes, isNull);
      expect(invoice.lineItemsJson, isNull);
    });

    test('can store line items as JSON', () async {
      final lineItemsJson =
          '[{"description":"Dev","quantity":10,"unitPrice":150}]';

      final id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
            invoiceIdString: 'INV-001',
            clientId: clientId,
            issueDate: DateTime(2025, 3, 1),
            dueDate: DateTime(2025, 3, 31),
            totalAmount: 1500.0,
            status: 'Sent',
            lineItemsJson: Value(lineItemsJson),
          ));

      final invoice =
          await (db.select(db.invoices)..where((i) => i.id.equals(id)))
              .getSingle();

      expect(invoice.lineItemsJson, lineItemsJson);
    });
  });

  group('CompanySettings table', () {
    test('can upsert company settings', () async {
      await db.into(db.companySettings).insertOnConflictUpdate(
            CompanySettingsCompanion.insert(
              id: const Value(1),
              companyName: 'My Company',
              companyAddress: '123 Main St',
            ),
          );

      final settings = await (db.select(db.companySettings)
            ..where((s) => s.id.equals(1)))
          .getSingle();

      expect(settings.companyName, 'My Company');
      expect(settings.showLetterhead, true); // default
      expect(settings.logoPath, isNull);
    });
  });
}
