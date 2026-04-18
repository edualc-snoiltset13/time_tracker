import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertClient({String name = 'Test Client'}) async {
    return db.into(db.clients).insert(ClientsCompanion.insert(name: name));
  }

  Future<int> insertProject({
    required int clientId,
    String name = 'Test Project',
    double hourlyRate = 100.0,
  }) async {
    return db.into(db.projects).insert(ProjectsCompanion.insert(
      clientId: clientId,
      name: name,
      hourlyRate: hourlyRate,
    ));
  }

  group('Clients', () {
    test('insert and read', () async {
      final id = await insertClient(name: 'Acme Corp');
      final clients = await db.select(db.clients).get();
      expect(clients, hasLength(1));
      expect(clients.first.id, id);
      expect(clients.first.name, 'Acme Corp');
    });

    test('default currency is USD', () async {
      await insertClient();
      final client = (await db.select(db.clients).get()).first;
      expect(client.currency, 'USD');
    });

    test('nullable fields default to null', () async {
      await insertClient();
      final client = (await db.select(db.clients).get()).first;
      expect(client.email, isNull);
      expect(client.address, isNull);
    });

    test('update', () async {
      final id = await insertClient(name: 'Old Name');
      await (db.update(db.clients)..where((c) => c.id.equals(id)))
          .write(const ClientsCompanion(name: Value('New Name')));
      final client = (await db.select(db.clients).get()).first;
      expect(client.name, 'New Name');
    });

    test('delete', () async {
      final id = await insertClient();
      await (db.delete(db.clients)..where((c) => c.id.equals(id))).go();
      final clients = await db.select(db.clients).get();
      expect(clients, isEmpty);
    });
  });

  group('Projects', () {
    test('insert and read with client reference', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(
        clientId: clientId,
        name: 'Website Redesign',
        hourlyRate: 150.0,
      );

      final projects = await db.select(db.projects).get();
      expect(projects, hasLength(1));
      expect(projects.first.id, projectId);
      expect(projects.first.clientId, clientId);
      expect(projects.first.name, 'Website Redesign');
      expect(projects.first.hourlyRate, 150.0);
    });

    test('default status is Active', () async {
      final clientId = await insertClient();
      await insertProject(clientId: clientId);
      final project = (await db.select(db.projects).get()).first;
      expect(project.status, 'Active');
    });

    test('monthlyTimeLimit defaults to null', () async {
      final clientId = await insertClient();
      await insertProject(clientId: clientId);
      final project = (await db.select(db.projects).get()).first;
      expect(project.monthlyTimeLimit, isNull);
    });
  });

  group('TimeEntries', () {
    test('insert and read', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);
      final now = DateTime.now();

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Coding',
        startTime: now,
        category: 'Development',
      ));

      final entries = await db.select(db.timeEntries).get();
      expect(entries, hasLength(1));
      expect(entries.first.description, 'Coding');
      expect(entries.first.endTime, isNull);
    });

    test('defaults: isBillable=true, isBilled=false, isLogged=false', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Work',
        startTime: DateTime.now(),
        category: 'General',
      ));

      final entry = (await db.select(db.timeEntries).get()).first;
      expect(entry.isBillable, true);
      expect(entry.isBilled, false);
      expect(entry.isLogged, false);
    });

    test('entry with endTime set', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);
      final start = DateTime(2024, 1, 15, 9, 0);
      final end = DateTime(2024, 1, 15, 11, 30);

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Meeting',
        startTime: start,
        endTime: Value(end),
        category: 'Meeting',
      ));

      final entry = (await db.select(db.timeEntries).get()).first;
      expect(entry.endTime, isNotNull);
      final duration = entry.endTime!.difference(entry.startTime);
      expect(duration.inMinutes, 150);
    });
  });

  group('Expenses', () {
    test('insert with project reference', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Software license',
        projectId: Value(projectId),
        category: 'Software',
        amount: 99.99,
        date: DateTime(2024, 3, 1),
      ));

      final expenses = await db.select(db.expenses).get();
      expect(expenses, hasLength(1));
      expect(expenses.first.description, 'Software license');
      expect(expenses.first.amount, 99.99);
      expect(expenses.first.projectId, projectId);
    });

    test('insert with client reference only', () async {
      final clientId = await insertClient();

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Travel',
        clientId: Value(clientId),
        category: 'Travel',
        amount: 250.0,
        date: DateTime(2024, 3, 5),
      ));

      final expense = (await db.select(db.expenses).get()).first;
      expect(expense.clientId, clientId);
      expect(expense.projectId, isNull);
    });

    test('mileage expense with distance and costPerUnit', () async {
      final clientId = await insertClient();

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Client visit',
        clientId: Value(clientId),
        category: 'Mileage',
        amount: 33.50,
        date: DateTime(2024, 3, 10),
        distance: const Value(50.0),
        costPerUnit: const Value(0.67),
      ));

      final expense = (await db.select(db.expenses).get()).first;
      expect(expense.distance, 50.0);
      expect(expense.costPerUnit, 0.67);
    });

    test('isBilled defaults to false', () async {
      final clientId = await insertClient();
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Lunch',
        clientId: Value(clientId),
        category: 'Meals',
        amount: 25.0,
        date: DateTime(2024, 3, 1),
      ));
      final expense = (await db.select(db.expenses).get()).first;
      expect(expense.isBilled, false);
    });
  });

  group('Invoices', () {
    test('insert and read', () async {
      final clientId = await insertClient();

      await db.into(db.invoices).insert(InvoicesCompanion.insert(
        invoiceIdString: 'INV-001',
        clientId: clientId,
        issueDate: DateTime(2024, 3, 1),
        dueDate: DateTime(2024, 3, 31),
        totalAmount: 1500.0,
        status: 'Draft',
      ));

      final invoices = await db.select(db.invoices).get();
      expect(invoices, hasLength(1));
      expect(invoices.first.invoiceIdString, 'INV-001');
      expect(invoices.first.totalAmount, 1500.0);
      expect(invoices.first.status, 'Draft');
    });

    test('stores and retrieves line items JSON', () async {
      final clientId = await insertClient();
      final lineItemsJson =
          '[{"description":"Dev","quantity":10,"unitPrice":100}]';

      await db.into(db.invoices).insert(InvoicesCompanion.insert(
        invoiceIdString: 'INV-002',
        clientId: clientId,
        issueDate: DateTime(2024, 4, 1),
        dueDate: DateTime(2024, 4, 30),
        totalAmount: 1000.0,
        status: 'Sent',
        lineItemsJson: Value(lineItemsJson),
      ));

      final invoice = (await db.select(db.invoices).get()).first;
      expect(invoice.lineItemsJson, lineItemsJson);
    });

    test('notes defaults to null', () async {
      final clientId = await insertClient();
      await db.into(db.invoices).insert(InvoicesCompanion.insert(
        invoiceIdString: 'INV-003',
        clientId: clientId,
        issueDate: DateTime(2024, 5, 1),
        dueDate: DateTime(2024, 5, 31),
        totalAmount: 500.0,
        status: 'Paid',
      ));
      final invoice = (await db.select(db.invoices).get()).first;
      expect(invoice.notes, isNull);
    });
  });

  group('Todos', () {
    test('insert and read', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.todos).insert(TodosCompanion.insert(
        title: 'Fix bug #42',
        projectId: projectId,
        category: 'Bug',
        deadline: DateTime(2024, 4, 15),
        priority: 'P1',
        startTime: DateTime(2024, 4, 10),
      ));

      final todos = await db.select(db.todos).get();
      expect(todos, hasLength(1));
      expect(todos.first.title, 'Fix bug #42');
      expect(todos.first.priority, 'P1');
    });

    test('isCompleted defaults to false', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.todos).insert(TodosCompanion.insert(
        title: 'Task',
        projectId: projectId,
        category: 'Feature',
        deadline: DateTime(2024, 5, 1),
        priority: 'P2',
        startTime: DateTime(2024, 4, 20),
      ));

      final todo = (await db.select(db.todos).get()).first;
      expect(todo.isCompleted, false);
    });

    test('toggle completion', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      final id = await db.into(db.todos).insert(TodosCompanion.insert(
        title: 'Complete me',
        projectId: projectId,
        category: 'Task',
        deadline: DateTime(2024, 5, 1),
        priority: 'P3',
        startTime: DateTime(2024, 4, 25),
      ));

      await (db.update(db.todos)..where((t) => t.id.equals(id)))
          .write(const TodosCompanion(isCompleted: Value(true)));

      final todo = (await db.select(db.todos).get()).first;
      expect(todo.isCompleted, true);
    });
  });

  group('CompanySettings', () {
    test('insert and read', () async {
      await db.into(db.companySettings).insert(CompanySettingsCompanion.insert(
        companyName: 'My Studio',
        companyAddress: '123 Main St',
      ));

      final settings = await db.select(db.companySettings).get();
      expect(settings, hasLength(1));
      expect(settings.first.companyName, 'My Studio');
      expect(settings.first.companyAddress, '123 Main St');
    });

    test('showLetterhead defaults to true', () async {
      await db.into(db.companySettings).insert(CompanySettingsCompanion.insert(
        companyName: 'Studio',
        companyAddress: 'Addr',
      ));
      final setting = (await db.select(db.companySettings).get()).first;
      expect(setting.showLetterhead, true);
    });

    test('logoPath defaults to null', () async {
      await db.into(db.companySettings).insert(CompanySettingsCompanion.insert(
        companyName: 'Studio',
        companyAddress: 'Addr',
      ));
      final setting = (await db.select(db.companySettings).get()).first;
      expect(setting.logoPath, isNull);
    });

    test('update settings', () async {
      final id = await db.into(db.companySettings).insert(
        CompanySettingsCompanion.insert(
          companyName: 'Old Name',
          companyAddress: 'Old Addr',
        ),
      );

      await (db.update(db.companySettings)..where((s) => s.id.equals(id)))
          .write(const CompanySettingsCompanion(
        companyName: Value('New Studio'),
        companyAddress: Value('456 Oak Ave'),
      ));

      final setting = (await db.select(db.companySettings).get()).first;
      expect(setting.companyName, 'New Studio');
      expect(setting.companyAddress, '456 Oak Ave');
    });
  });

  group('Cascade deletes', () {
    test('deleting a client cascades to projects', () async {
      final clientId = await insertClient();
      await insertProject(clientId: clientId, name: 'Project A');
      await insertProject(clientId: clientId, name: 'Project B');

      expect(await db.select(db.projects).get(), hasLength(2));

      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      expect(await db.select(db.clients).get(), isEmpty);
      expect(await db.select(db.projects).get(), isEmpty);
    });

    test('deleting a client cascades through projects to time entries', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Work',
        startTime: DateTime.now(),
        category: 'Dev',
      ));

      expect(await db.select(db.timeEntries).get(), hasLength(1));

      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      expect(await db.select(db.timeEntries).get(), isEmpty);
    });

    test('deleting a project cascades to time entries and todos', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Entry',
        startTime: DateTime.now(),
        category: 'Dev',
      ));
      await db.into(db.todos).insert(TodosCompanion.insert(
        title: 'Todo',
        projectId: projectId,
        category: 'Task',
        deadline: DateTime(2024, 12, 31),
        priority: 'P1',
        startTime: DateTime(2024, 1, 1),
      ));

      expect(await db.select(db.timeEntries).get(), hasLength(1));
      expect(await db.select(db.todos).get(), hasLength(1));

      await (db.delete(db.projects)..where((p) => p.id.equals(projectId))).go();

      expect(await db.select(db.timeEntries).get(), isEmpty);
      expect(await db.select(db.todos).get(), isEmpty);
    });

    test('deleting a client cascades to expenses', () async {
      final clientId = await insertClient();

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Expense',
        clientId: Value(clientId),
        category: 'Misc',
        amount: 50.0,
        date: DateTime(2024, 6, 1),
      ));

      expect(await db.select(db.expenses).get(), hasLength(1));

      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      expect(await db.select(db.expenses).get(), isEmpty);
    });

    test('deleting a client cascades to invoices', () async {
      final clientId = await insertClient();

      await db.into(db.invoices).insert(InvoicesCompanion.insert(
        invoiceIdString: 'INV-DEL',
        clientId: clientId,
        issueDate: DateTime(2024, 6, 1),
        dueDate: DateTime(2024, 6, 30),
        totalAmount: 1000.0,
        status: 'Draft',
      ));

      expect(await db.select(db.invoices).get(), hasLength(1));

      await (db.delete(db.clients)..where((c) => c.id.equals(clientId))).go();

      expect(await db.select(db.invoices).get(), isEmpty);
    });

    test('deleting a project cascades to expenses linked by projectId', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(clientId: clientId);

      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: 'Project expense',
        projectId: Value(projectId),
        category: 'Software',
        amount: 200.0,
        date: DateTime(2024, 7, 1),
      ));

      expect(await db.select(db.expenses).get(), hasLength(1));

      await (db.delete(db.projects)..where((p) => p.id.equals(projectId))).go();

      expect(await db.select(db.expenses).get(), isEmpty);
    });
  });

  group('Joins', () {
    test('join time entries with projects', () async {
      final clientId = await insertClient();
      final projectId = await insertProject(
        clientId: clientId,
        name: 'API Work',
        hourlyRate: 120.0,
      );
      final start = DateTime(2024, 3, 1, 9, 0);
      final end = DateTime(2024, 3, 1, 11, 0);

      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: 'Build endpoints',
        startTime: start,
        endTime: Value(end),
        category: 'Development',
      ));

      final query = db.select(db.timeEntries).join([
        innerJoin(db.projects, db.projects.id.equalsExp(db.timeEntries.projectId)),
      ]);

      final results = await query.get();
      expect(results, hasLength(1));

      final entry = results.first.readTable(db.timeEntries);
      final project = results.first.readTable(db.projects);
      expect(entry.description, 'Build endpoints');
      expect(project.name, 'API Work');
      expect(project.hourlyRate, 120.0);

      final hours = end.difference(start).inMinutes / 60.0;
      final earnings = hours * project.hourlyRate;
      expect(earnings, 240.0);
    });
  });
}
