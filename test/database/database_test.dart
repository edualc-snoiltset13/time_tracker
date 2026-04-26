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

  // -- Helpers --

  Future<int> addClient({
    String name = 'Test Client',
    String? email,
    String? address,
    String currency = 'USD',
  }) {
    return db.into(db.clients).insert(ClientsCompanion.insert(
          name: name,
          email: Value(email),
          address: Value(address),
          currency: Value(currency),
        ));
  }

  Future<int> addProject({
    required int clientId,
    String name = 'Test Project',
    double hourlyRate = 100.0,
  }) {
    return db.into(db.projects).insert(ProjectsCompanion.insert(
          clientId: clientId,
          name: name,
          hourlyRate: hourlyRate,
        ));
  }

  Future<int> addTimeEntry({
    required int projectId,
    String description = 'Work',
    required DateTime startTime,
    DateTime? endTime,
    String category = 'Development',
  }) {
    return db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
          projectId: projectId,
          description: description,
          startTime: startTime,
          endTime: Value(endTime),
          category: category,
        ));
  }

  Future<int> addExpense({
    String description = 'Expense',
    int? projectId,
    int? clientId,
    String category = 'Misc',
    double amount = 50.0,
    DateTime? date,
  }) {
    return db.into(db.expenses).insert(ExpensesCompanion.insert(
          description: description,
          projectId: Value(projectId),
          clientId: Value(clientId),
          category: category,
          amount: amount,
          date: date ?? DateTime(2024, 6, 1),
        ));
  }

  Future<int> addInvoice({
    required int clientId,
    String invoiceIdString = 'INV-001',
    double totalAmount = 1000.0,
    String status = 'Draft',
    String? lineItemsJson,
    String? notes,
  }) {
    return db.into(db.invoices).insert(InvoicesCompanion.insert(
          invoiceIdString: invoiceIdString,
          clientId: clientId,
          issueDate: DateTime(2024, 3, 1),
          dueDate: DateTime(2024, 3, 31),
          totalAmount: totalAmount,
          status: status,
          lineItemsJson: Value(lineItemsJson),
          notes: Value(notes),
        ));
  }

  Future<int> addTodo({
    required int projectId,
    String title = 'Task',
    String category = 'Feature',
    String priority = 'P2',
  }) {
    return db.into(db.todos).insert(TodosCompanion.insert(
          title: title,
          projectId: projectId,
          category: category,
          deadline: DateTime(2024, 12, 31),
          priority: priority,
          startTime: DateTime(2024, 1, 1),
        ));
  }

  // -- Clients --

  group('Clients', () {
    test('insert and retrieve', () async {
      final id = await addClient(name: 'Acme Corp');
      final all = await db.select(db.clients).get();
      expect(all, hasLength(1));
      expect(all.first.id, id);
      expect(all.first.name, 'Acme Corp');
    });

    test('defaults: currency=USD, email=null, address=null', () async {
      await db
          .into(db.clients)
          .insert(ClientsCompanion.insert(name: 'Minimal'));
      final c = (await db.select(db.clients).get()).first;
      expect(c.currency, 'USD');
      expect(c.email, isNull);
      expect(c.address, isNull);
    });

    test('stores optional fields', () async {
      await addClient(
        name: 'Full',
        email: 'a@b.com',
        address: '123 Main St',
        currency: 'EUR',
      );
      final c = (await db.select(db.clients).get()).first;
      expect(c.email, 'a@b.com');
      expect(c.address, '123 Main St');
      expect(c.currency, 'EUR');
    });

    test('update a field', () async {
      final id = await addClient(name: 'Old');
      await (db.update(db.clients)..where((c) => c.id.equals(id)))
          .write(const ClientsCompanion(name: Value('New')));
      final c = (await db.select(db.clients).get()).first;
      expect(c.name, 'New');
    });

    test('delete by id', () async {
      final id = await addClient();
      await (db.delete(db.clients)..where((c) => c.id.equals(id))).go();
      expect(await db.select(db.clients).get(), isEmpty);
    });

    test('insert multiple and count', () async {
      await addClient(name: 'A');
      await addClient(name: 'B');
      await addClient(name: 'C');
      expect(await db.select(db.clients).get(), hasLength(3));
    });
  });

  // -- Projects --

  group('Projects', () {
    test('insert with client FK', () async {
      final cid = await addClient();
      final pid = await addProject(
          clientId: cid, name: 'Website', hourlyRate: 150.0);
      final p = (await db.select(db.projects).get()).first;
      expect(p.id, pid);
      expect(p.clientId, cid);
      expect(p.name, 'Website');
      expect(p.hourlyRate, 150.0);
    });

    test('defaults: status=Active, monthlyTimeLimit=null', () async {
      final cid = await addClient();
      await addProject(clientId: cid);
      final p = (await db.select(db.projects).get()).first;
      expect(p.status, 'Active');
      expect(p.monthlyTimeLimit, isNull);
    });

    test('multiple projects per client', () async {
      final cid = await addClient();
      await addProject(clientId: cid, name: 'P1');
      await addProject(clientId: cid, name: 'P2');
      final projects = await (db.select(db.projects)
            ..where((p) => p.clientId.equals(cid)))
          .get();
      expect(projects, hasLength(2));
    });

    test('join projects with clients', () async {
      final cid = await addClient(name: 'Acme');
      await addProject(clientId: cid, name: 'Backend');

      final rows = await db.select(db.projects).join([
        innerJoin(db.clients, db.clients.id.equalsExp(db.projects.clientId)),
      ]).get();

      expect(rows, hasLength(1));
      expect(rows.first.readTable(db.projects).name, 'Backend');
      expect(rows.first.readTable(db.clients).name, 'Acme');
    });
  });

  // -- TimeEntries --

  group('TimeEntries', () {
    test('insert with null endTime (active timer)', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(
          projectId: pid, startTime: DateTime(2024, 1, 1, 9, 0));
      final e = (await db.select(db.timeEntries).get()).first;
      expect(e.endTime, isNull);
    });

    test('defaults: isBillable=true, isBilled=false, isLogged=false',
        () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(projectId: pid, startTime: DateTime.now());
      final e = (await db.select(db.timeEntries).get()).first;
      expect(e.isBillable, true);
      expect(e.isBilled, false);
      expect(e.isLogged, false);
    });

    test('duration calculation from start/end', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final start = DateTime(2024, 1, 15, 9, 0);
      final end = DateTime(2024, 1, 15, 11, 30);
      await addTimeEntry(projectId: pid, startTime: start, endTime: end);
      final e = (await db.select(db.timeEntries).get()).first;
      expect(e.endTime!.difference(e.startTime).inMinutes, 150);
    });

    test('filter active timers (endTime is null)', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(projectId: pid, startTime: DateTime(2024, 1, 1, 9, 0));
      await addTimeEntry(
        projectId: pid,
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 10, 0),
      );

      final active =
          await (db.select(db.timeEntries)..where((t) => t.endTime.isNull()))
              .get();
      expect(active, hasLength(1));

      final completed = await (db.select(db.timeEntries)
            ..where((t) => t.endTime.isNotNull()))
          .get();
      expect(completed, hasLength(1));
    });

    test('update isLogged flag', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final eid = await addTimeEntry(projectId: pid, startTime: DateTime.now());

      await (db.update(db.timeEntries)..where((t) => t.id.equals(eid)))
          .write(const TimeEntriesCompanion(isLogged: Value(true)));

      final e = (await db.select(db.timeEntries).get()).first;
      expect(e.isLogged, true);
    });

    test('update isBilled flag', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final eid = await addTimeEntry(projectId: pid, startTime: DateTime.now());

      await (db.update(db.timeEntries)..where((t) => t.id.equals(eid)))
          .write(const TimeEntriesCompanion(isBilled: Value(true)));

      final e = (await db.select(db.timeEntries).get()).first;
      expect(e.isBilled, true);
    });

    test('order by startTime descending', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(
          projectId: pid,
          description: 'Early',
          startTime: DateTime(2024, 1, 1));
      await addTimeEntry(
          projectId: pid,
          description: 'Late',
          startTime: DateTime(2024, 6, 1));

      final entries = await (db.select(db.timeEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .get();
      expect(entries.first.description, 'Late');
      expect(entries.last.description, 'Early');
    });

    test('join with projects for earnings calculation', () async {
      final cid = await addClient();
      final pid =
          await addProject(clientId: cid, name: 'API', hourlyRate: 120.0);
      final start = DateTime(2024, 3, 1, 9, 0);
      final end = DateTime(2024, 3, 1, 11, 0);
      await addTimeEntry(projectId: pid, startTime: start, endTime: end);

      final rows = await db.select(db.timeEntries).join([
        innerJoin(
            db.projects, db.projects.id.equalsExp(db.timeEntries.projectId)),
      ]).get();

      final entry = rows.first.readTable(db.timeEntries);
      final project = rows.first.readTable(db.projects);
      final hours = entry.endTime!.difference(entry.startTime).inMinutes / 60.0;
      expect(hours * project.hourlyRate, 240.0);
    });

    test('filter by date range', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(
          projectId: pid,
          description: 'Jan',
          startTime: DateTime(2024, 1, 15),
          endTime: DateTime(2024, 1, 15, 1));
      await addTimeEntry(
          projectId: pid,
          description: 'Mar',
          startTime: DateTime(2024, 3, 15),
          endTime: DateTime(2024, 3, 15, 1));
      await addTimeEntry(
          projectId: pid,
          description: 'Jun',
          startTime: DateTime(2024, 6, 15),
          endTime: DateTime(2024, 6, 15, 1));

      final febToApr = await (db.select(db.timeEntries)
            ..where((t) => t.startTime.isBetweenValues(
                DateTime(2024, 2, 1), DateTime(2024, 4, 30))))
          .get();
      expect(febToApr, hasLength(1));
      expect(febToApr.first.description, 'Mar');
    });
  });

  // -- Expenses --

  group('Expenses', () {
    test('insert with project reference', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addExpense(description: 'License', projectId: pid, amount: 99.99);
      final e = (await db.select(db.expenses).get()).first;
      expect(e.description, 'License');
      expect(e.amount, 99.99);
      expect(e.projectId, pid);
      expect(e.clientId, isNull);
    });

    test('insert with client reference only', () async {
      final cid = await addClient();
      await addExpense(description: 'Travel', clientId: cid);
      final e = (await db.select(db.expenses).get()).first;
      expect(e.clientId, cid);
      expect(e.projectId, isNull);
    });

    test('mileage with distance and costPerUnit', () async {
      final cid = await addClient();
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            description: 'Drive',
            clientId: Value(cid),
            category: 'Mileage',
            amount: 33.50,
            date: DateTime(2024, 3, 10),
            distance: const Value(50.0),
            costPerUnit: const Value(0.67),
          ));
      final e = (await db.select(db.expenses).get()).first;
      expect(e.distance, 50.0);
      expect(e.costPerUnit, 0.67);
    });

    test('isBilled defaults to false', () async {
      final cid = await addClient();
      await addExpense(clientId: cid);
      expect((await db.select(db.expenses).get()).first.isBilled, false);
    });

    test('order by date descending', () async {
      final cid = await addClient();
      await addExpense(
          clientId: cid, description: 'Old', date: DateTime(2024, 1, 1));
      await addExpense(
          clientId: cid, description: 'New', date: DateTime(2024, 6, 1));

      final expenses = await (db.select(db.expenses)
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();
      expect(expenses.first.description, 'New');
    });
  });

  // -- Invoices --

  group('Invoices', () {
    test('insert and retrieve', () async {
      final cid = await addClient();
      await addInvoice(
          clientId: cid,
          invoiceIdString: 'INV-001',
          totalAmount: 1500.0,
          status: 'Draft');
      final inv = (await db.select(db.invoices).get()).first;
      expect(inv.invoiceIdString, 'INV-001');
      expect(inv.totalAmount, 1500.0);
      expect(inv.status, 'Draft');
    });

    test('notes and lineItemsJson default to null', () async {
      final cid = await addClient();
      await addInvoice(clientId: cid);
      final inv = (await db.select(db.invoices).get()).first;
      expect(inv.notes, isNull);
      expect(inv.lineItemsJson, isNull);
    });

    test('stores and retrieves lineItemsJson', () async {
      final cid = await addClient();
      final items = [
        LineItem(description: 'Dev', quantity: 10, unitPrice: 100),
      ];
      final json = lineItemsToJson(items);
      await addInvoice(clientId: cid, lineItemsJson: json);

      final inv = (await db.select(db.invoices).get()).first;
      final restored = lineItemsFromJson(inv.lineItemsJson!);
      expect(restored, hasLength(1));
      expect(restored.first.total, 1000.0);
    });

    test('stores notes', () async {
      final cid = await addClient();
      await addInvoice(clientId: cid, notes: 'Net 30 payment terms');
      final inv = (await db.select(db.invoices).get()).first;
      expect(inv.notes, 'Net 30 payment terms');
    });

    test('join with clients', () async {
      final cid = await addClient(name: 'Acme');
      await addInvoice(clientId: cid);

      final rows = await db.select(db.invoices).join([
        innerJoin(db.clients, db.clients.id.equalsExp(db.invoices.clientId)),
      ]).get();

      expect(rows.first.readTable(db.clients).name, 'Acme');
    });
  });

  // -- Todos --

  group('Todos', () {
    test('insert and retrieve', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTodo(projectId: pid, title: 'Fix bug', priority: 'P1');
      final t = (await db.select(db.todos).get()).first;
      expect(t.title, 'Fix bug');
      expect(t.priority, 'P1');
    });

    test('isCompleted defaults to false', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTodo(projectId: pid);
      expect((await db.select(db.todos).get()).first.isCompleted, false);
    });

    test('toggle completion on then off', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final id = await addTodo(projectId: pid);

      await (db.update(db.todos)..where((t) => t.id.equals(id)))
          .write(const TodosCompanion(isCompleted: Value(true)));
      expect((await db.select(db.todos).get()).first.isCompleted, true);

      await (db.update(db.todos)..where((t) => t.id.equals(id)))
          .write(const TodosCompanion(isCompleted: Value(false)));
      expect((await db.select(db.todos).get()).first.isCompleted, false);
    });

    test('description and estimatedHours are nullable', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTodo(projectId: pid);
      final t = (await db.select(db.todos).get()).first;
      expect(t.description, isNull);
      expect(t.estimatedHours, isNull);
    });

    test('order by deadline', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await db.into(db.todos).insert(TodosCompanion.insert(
            title: 'Later',
            projectId: pid,
            category: 'Task',
            deadline: DateTime(2024, 12, 1),
            priority: 'P3',
            startTime: DateTime(2024, 1, 1),
          ));
      await db.into(db.todos).insert(TodosCompanion.insert(
            title: 'Sooner',
            projectId: pid,
            category: 'Task',
            deadline: DateTime(2024, 6, 1),
            priority: 'P1',
            startTime: DateTime(2024, 1, 1),
          ));

      final todos = await (db.select(db.todos)
            ..orderBy([(t) => OrderingTerm.asc(t.deadline)]))
          .get();
      expect(todos.first.title, 'Sooner');
      expect(todos.last.title, 'Later');
    });

    test('delete completed todos', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final id1 = await addTodo(projectId: pid, title: 'Done');
      await addTodo(projectId: pid, title: 'Pending');

      await (db.update(db.todos)..where((t) => t.id.equals(id1)))
          .write(const TodosCompanion(isCompleted: Value(true)));

      await (db.delete(db.todos)..where((t) => t.isCompleted.equals(true)))
          .go();

      final remaining = await db.select(db.todos).get();
      expect(remaining, hasLength(1));
      expect(remaining.first.title, 'Pending');
    });
  });

  // -- CompanySettings --

  group('CompanySettings', () {
    test('insert and retrieve', () async {
      await db
          .into(db.companySettings)
          .insert(CompanySettingsCompanion.insert(
            companyName: 'Studio',
            companyAddress: '123 Main St',
          ));
      final s = (await db.select(db.companySettings).get()).first;
      expect(s.companyName, 'Studio');
      expect(s.companyAddress, '123 Main St');
    });

    test('defaults: showLetterhead=true, logoPath=null', () async {
      await db
          .into(db.companySettings)
          .insert(CompanySettingsCompanion.insert(
            companyName: 'X',
            companyAddress: 'Y',
          ));
      final s = (await db.select(db.companySettings).get()).first;
      expect(s.showLetterhead, true);
      expect(s.logoPath, isNull);
    });

    test('update all fields', () async {
      final id = await db
          .into(db.companySettings)
          .insert(CompanySettingsCompanion.insert(
            companyName: 'Old',
            companyAddress: 'Old Addr',
          ));

      await (db.update(db.companySettings)..where((s) => s.id.equals(id)))
          .write(const CompanySettingsCompanion(
        companyName: Value('New Studio'),
        companyAddress: Value('456 Oak Ave'),
        showLetterhead: Value(false),
        logoPath: Value('/path/to/logo.png'),
      ));

      final s = (await db.select(db.companySettings).get()).first;
      expect(s.companyName, 'New Studio');
      expect(s.companyAddress, '456 Oak Ave');
      expect(s.showLetterhead, false);
      expect(s.logoPath, '/path/to/logo.png');
    });
  });

  // -- Cascade deletes --

  group('Cascade deletes', () {
    test('client delete cascades to projects', () async {
      final cid = await addClient();
      await addProject(clientId: cid, name: 'P1');
      await addProject(clientId: cid, name: 'P2');
      expect(await db.select(db.projects).get(), hasLength(2));

      await (db.delete(db.clients)..where((c) => c.id.equals(cid))).go();
      expect(await db.select(db.projects).get(), isEmpty);
    });

    test('client delete cascades through projects to time entries', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(projectId: pid, startTime: DateTime.now());

      await (db.delete(db.clients)..where((c) => c.id.equals(cid))).go();
      expect(await db.select(db.timeEntries).get(), isEmpty);
    });

    test('client delete cascades to invoices', () async {
      final cid = await addClient();
      await addInvoice(clientId: cid);

      await (db.delete(db.clients)..where((c) => c.id.equals(cid))).go();
      expect(await db.select(db.invoices).get(), isEmpty);
    });

    test('client delete cascades to expenses (via clientId)', () async {
      final cid = await addClient();
      await addExpense(clientId: cid);

      await (db.delete(db.clients)..where((c) => c.id.equals(cid))).go();
      expect(await db.select(db.expenses).get(), isEmpty);
    });

    test('project delete cascades to time entries and todos', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(projectId: pid, startTime: DateTime.now());
      await addTodo(projectId: pid);

      await (db.delete(db.projects)..where((p) => p.id.equals(pid))).go();
      expect(await db.select(db.timeEntries).get(), isEmpty);
      expect(await db.select(db.todos).get(), isEmpty);
    });

    test('project delete cascades to expenses (via projectId)', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addExpense(projectId: pid);

      await (db.delete(db.projects)..where((p) => p.id.equals(pid))).go();
      expect(await db.select(db.expenses).get(), isEmpty);
    });

    test('deleting one client does not affect another', () async {
      final cid1 = await addClient(name: 'A');
      final cid2 = await addClient(name: 'B');
      await addProject(clientId: cid1, name: 'PA');
      await addProject(clientId: cid2, name: 'PB');

      await (db.delete(db.clients)..where((c) => c.id.equals(cid1))).go();

      expect(await db.select(db.clients).get(), hasLength(1));
      final projects = await db.select(db.projects).get();
      expect(projects, hasLength(1));
      expect(projects.first.name, 'PB');
    });

    test('deep cascade: client → project → entries + todos + expenses',
        () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      await addTimeEntry(projectId: pid, startTime: DateTime.now());
      await addTodo(projectId: pid);
      await addExpense(projectId: pid);
      await addInvoice(clientId: cid);

      await (db.delete(db.clients)..where((c) => c.id.equals(cid))).go();

      expect(await db.select(db.clients).get(), isEmpty);
      expect(await db.select(db.projects).get(), isEmpty);
      expect(await db.select(db.timeEntries).get(), isEmpty);
      expect(await db.select(db.todos).get(), isEmpty);
      expect(await db.select(db.expenses).get(), isEmpty);
      expect(await db.select(db.invoices).get(), isEmpty);
    });
  });

  // -- Reactive streams --

  group('Streams', () {
    test('clients stream emits on insert', () async {
      final stream = db.select(db.clients).watch();

      expectLater(
        stream,
        emitsInOrder([
          hasLength(0),
          hasLength(1),
        ]),
      );

      await addClient(name: 'Stream Test');
    });

    test('time entries stream emits on update', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      final eid = await addTimeEntry(projectId: pid, startTime: DateTime.now());

      final stream = db.select(db.timeEntries).watch();

      final first = await stream.first;
      expect(first.first.isLogged, false);

      await (db.update(db.timeEntries)..where((t) => t.id.equals(eid)))
          .write(const TimeEntriesCompanion(isLogged: Value(true)));

      final second = await stream.first;
      expect(second.first.isLogged, true);
    });
  });

  // -- Complex queries --

  group('Complex queries', () {
    test('aggregate hours and earnings across projects', () async {
      final cid = await addClient();
      final p1 =
          await addProject(clientId: cid, name: 'P1', hourlyRate: 100.0);
      final p2 =
          await addProject(clientId: cid, name: 'P2', hourlyRate: 200.0);

      await addTimeEntry(
        projectId: p1,
        startTime: DateTime(2024, 3, 1, 9, 0),
        endTime: DateTime(2024, 3, 1, 11, 0),
      );
      await addTimeEntry(
        projectId: p2,
        startTime: DateTime(2024, 3, 1, 13, 0),
        endTime: DateTime(2024, 3, 1, 14, 30),
      );

      final rows = await db.select(db.timeEntries).join([
        innerJoin(
            db.projects, db.projects.id.equalsExp(db.timeEntries.projectId)),
      ]).get();

      double totalHours = 0;
      double totalEarnings = 0;
      for (final row in rows) {
        final entry = row.readTable(db.timeEntries);
        final project = row.readTable(db.projects);
        final hours =
            entry.endTime!.difference(entry.startTime).inMinutes / 60.0;
        totalHours += hours;
        totalEarnings += hours * project.hourlyRate;
      }

      expect(totalHours, 3.5);
      expect(totalEarnings, 500.0);
    });

    test('filter unbilled time entries for a client', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);

      final eid1 = await addTimeEntry(
        projectId: pid,
        description: 'Billed',
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 10, 0),
      );
      await (db.update(db.timeEntries)..where((t) => t.id.equals(eid1)))
          .write(const TimeEntriesCompanion(isBilled: Value(true)));

      await addTimeEntry(
        projectId: pid,
        description: 'Unbilled',
        startTime: DateTime(2024, 1, 2, 9, 0),
        endTime: DateTime(2024, 1, 2, 10, 0),
      );

      final unbilled = await (db.select(db.timeEntries)
            ..where((t) => t.isBilled.equals(false)))
          .get();
      expect(unbilled, hasLength(1));
      expect(unbilled.first.description, 'Unbilled');
    });

    test('limit query results', () async {
      final cid = await addClient();
      final pid = await addProject(clientId: cid);
      for (var i = 0; i < 10; i++) {
        await addTimeEntry(
          projectId: pid,
          description: 'Entry $i',
          startTime: DateTime(2024, 1, 1 + i),
          endTime: DateTime(2024, 1, 1 + i, 1),
        );
      }

      final limited = await (db.select(db.timeEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(5))
          .get();
      expect(limited, hasLength(5));
      expect(limited.first.description, 'Entry 9');
    });
  });
}
