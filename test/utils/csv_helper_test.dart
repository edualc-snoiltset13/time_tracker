import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/utils/csv_helper.dart';

Future<List<List<dynamic>>> readCsvFile(String path) async {
  final contents = await File(path).readAsString();
  return const CsvToListConverter().convert(contents);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addClient({String name = 'Test', String currency = 'USD'}) {
    return db.into(db.clients).insert(ClientsCompanion.insert(
          name: name,
          currency: Value(currency),
        ));
  }

  Future<int> addProject({required int clientId, String name = 'Proj'}) {
    return db.into(db.projects).insert(ProjectsCompanion.insert(
          clientId: clientId,
          name: name,
          hourlyRate: 100.0,
        ));
  }

  group('exportTableToCSV', () {
    test('returns null for empty table', () async {
      final path = await exportTableToCSV(db: db, tableName: 'clients');
      expect(path, isNull);
    });

    test('returns null for unknown table name', () async {
      final path = await exportTableToCSV(db: db, tableName: 'nonexistent');
      expect(path, isNull);
    });

    test('exports clients to CSV file on disk', () async {
      await addClient(name: 'Acme Corp', currency: 'EUR');
      await addClient(name: 'Beta Inc');

      final path = await exportTableToCSV(db: db, tableName: 'clients');
      expect(path, isNotNull);
      expect(path, endsWith('.csv'));

      final rows = await readCsvFile(path!);
      expect(rows, hasLength(3));
      expect(rows[0], ['id', 'name', 'email', 'address', 'currency']);
      expect(rows[1][1], 'Acme Corp');
      expect(rows[1][4], 'EUR');
      expect(rows[2][1], 'Beta Inc');
      expect(rows[2][4], 'USD');

      await File(path).delete();
    });

    test('exports projects with correct columns', () async {
      final cid = await addClient();
      await addProject(clientId: cid, name: 'Website');

      final path = await exportTableToCSV(db: db, tableName: 'projects');
      expect(path, isNotNull);

      final rows = await readCsvFile(path!);
      expect(rows[0], ['id', 'clientId', 'name', 'hourlyRate', 'monthlyTimeLimit', 'status']);
      expect(rows[1][2], 'Website');
      expect(rows[1][3], 100.0);
      expect(rows[1][5], 'Active');

      await File(path).delete();
    });

    test('exports time entries with ISO timestamps', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            projectId: pid,
            description: 'Coding session',
            startTime: DateTime(2024, 3, 1, 9, 0, 0),
            endTime: Value(DateTime(2024, 3, 1, 11, 30, 0)),
            category: 'Development',
          ));

      final path = await exportTableToCSV(db: db, tableName: 'time_entries');
      final rows = await readCsvFile(path!);

      expect(rows[1][2], 'Coding session');
      expect(rows[1][3], '2024-03-01 09:00:00');
      expect(rows[1][4], '2024-03-01 11:30:00');
      expect(rows[1][5], 'Development');

      await File(path).delete();
    });

    test('exports time entry with null endTime as empty string', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            projectId: pid,
            description: 'Active',
            startTime: DateTime(2024, 3, 1, 9, 0, 0),
            category: 'Dev',
          ));

      final path = await exportTableToCSV(db: db, tableName: 'time_entries');
      final rows = await readCsvFile(path!);
      expect(rows[1][4], '');

      await File(path).delete();
    });

    test('exports expenses with optional fields', () async {
      final cid = await addClient();
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            description: 'Mileage',
            clientId: Value(cid),
            category: 'Travel',
            amount: 33.50,
            date: DateTime(2024, 6, 1),
            distance: const Value(50.0),
            costPerUnit: const Value(0.67),
          ));

      final path = await exportTableToCSV(db: db, tableName: 'expenses');
      final rows = await readCsvFile(path!);
      expect(rows[1][1], 'Mileage');
      expect(rows[1][5], 33.5);
      expect(rows[1][7], 50.0);
      expect(rows[1][8], 0.67);

      await File(path).delete();
    });

    test('exports invoices', () async {
      final cid = await addClient();
      await db.into(db.invoices).insert(InvoicesCompanion.insert(
            invoiceIdString: 'INV-001',
            clientId: cid,
            issueDate: DateTime(2024, 3, 1),
            dueDate: DateTime(2024, 3, 31),
            totalAmount: 1500.0,
            status: 'Paid',
            notes: const Value('Thank you'),
          ));

      final path = await exportTableToCSV(db: db, tableName: 'invoices');
      final rows = await readCsvFile(path!);
      expect(rows[1][1], 'INV-001');
      expect(rows[1][5], 1500.0);
      expect(rows[1][6], 'Paid');
      expect(rows[1][7], 'Thank you');

      await File(path).delete();
    });

    test('exports todos', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await db.into(db.todos).insert(TodosCompanion.insert(
            title: 'Fix bug',
            projectId: pid,
            category: 'Bug',
            deadline: DateTime(2024, 12, 31),
            priority: 'P1',
            startTime: DateTime(2024, 1, 1),
            estimatedHours: const Value(3.5),
          ));

      final path = await exportTableToCSV(db: db, tableName: 'todos');
      final rows = await readCsvFile(path!);
      expect(rows[1][1], 'Fix bug');
      expect(rows[1][6], 'P1');
      expect(rows[1][9], 3.5);

      await File(path).delete();
    });

    test('exports multiple records', () async {
      for (var i = 1; i <= 5; i++) {
        await addClient(name: 'Client $i');
      }

      final path = await exportTableToCSV(db: db, tableName: 'clients');
      final rows = await readCsvFile(path!);
      expect(rows, hasLength(6));

      await File(path).delete();
    });
  });

  group('CsvImportResult', () {
    test('tracks inserted, skipped, and errors', () {
      final r = CsvImportResult(inserted: 5, skipped: 2, errors: ['err']);
      expect(r.inserted, 5);
      expect(r.skipped, 2);
      expect(r.errors, ['err']);
    });
  });
}
