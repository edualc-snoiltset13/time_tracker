import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_tracker/database/database.dart';

const _iso = 'yyyy-MM-dd HH:mm:ss';

String _fmt(DateTime? dt) => dt == null ? '' : DateFormat(_iso).format(dt);

DateTime _parse(String s) => DateFormat(_iso).parseStrict(s);

DateTime? _parseNullable(String s) => s.isEmpty ? null : _parse(s);

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

Future<String?> exportTableToCSV({
  required AppDatabase db,
  required String tableName,
}) async {
  final List<List<dynamic>> rows;

  switch (tableName) {
    case 'clients':
      rows = await _exportClients(db);
    case 'projects':
      rows = await _exportProjects(db);
    case 'time_entries':
      rows = await _exportTimeEntries(db);
    case 'expenses':
      rows = await _exportExpenses(db);
    case 'invoices':
      rows = await _exportInvoices(db);
    case 'todos':
      rows = await _exportTodos(db);
    default:
      return null;
  }

  if (rows.length <= 1) return null;

  final csv = const ListToCsvConverter().convert(rows);
  final dir = await getApplicationSupportDirectory();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File('${dir.path}/${tableName}_$timestamp.csv');
  await file.writeAsString(csv);
  return file.path;
}

Future<List<List<dynamic>>> _exportClients(AppDatabase db) async {
  final clients = await db.select(db.clients).get();
  return [
    ['id', 'name', 'email', 'address', 'currency'],
    ...clients.map((c) => [c.id, c.name, c.email ?? '', c.address ?? '', c.currency]),
  ];
}

Future<List<List<dynamic>>> _exportProjects(AppDatabase db) async {
  final projects = await db.select(db.projects).get();
  return [
    ['id', 'clientId', 'name', 'hourlyRate', 'monthlyTimeLimit', 'status'],
    ...projects.map((p) => [
      p.id, p.clientId, p.name, p.hourlyRate,
      p.monthlyTimeLimit ?? '', p.status,
    ]),
  ];
}

Future<List<List<dynamic>>> _exportTimeEntries(AppDatabase db) async {
  final entries = await db.select(db.timeEntries).get();
  return [
    ['id', 'projectId', 'description', 'startTime', 'endTime', 'category', 'isBillable', 'isBilled', 'isLogged'],
    ...entries.map((e) => [
      e.id, e.projectId, e.description, _fmt(e.startTime), _fmt(e.endTime),
      e.category, e.isBillable, e.isBilled, e.isLogged,
    ]),
  ];
}

Future<List<List<dynamic>>> _exportExpenses(AppDatabase db) async {
  final expenses = await db.select(db.expenses).get();
  return [
    ['id', 'description', 'projectId', 'clientId', 'category', 'amount', 'date', 'distance', 'costPerUnit', 'isBilled'],
    ...expenses.map((e) => [
      e.id, e.description, e.projectId ?? '', e.clientId ?? '',
      e.category, e.amount, _fmt(e.date), e.distance ?? '', e.costPerUnit ?? '',
      e.isBilled,
    ]),
  ];
}

Future<List<List<dynamic>>> _exportInvoices(AppDatabase db) async {
  final invoices = await db.select(db.invoices).get();
  return [
    ['id', 'invoiceIdString', 'clientId', 'issueDate', 'dueDate', 'totalAmount', 'status', 'notes', 'lineItemsJson'],
    ...invoices.map((i) => [
      i.id, i.invoiceIdString, i.clientId, _fmt(i.issueDate), _fmt(i.dueDate),
      i.totalAmount, i.status, i.notes ?? '', i.lineItemsJson ?? '',
    ]),
  ];
}

Future<List<List<dynamic>>> _exportTodos(AppDatabase db) async {
  final todos = await db.select(db.todos).get();
  return [
    ['id', 'title', 'description', 'projectId', 'category', 'deadline', 'priority', 'isCompleted', 'startTime', 'estimatedHours'],
    ...todos.map((t) => [
      t.id, t.title, t.description ?? '', t.projectId, t.category,
      _fmt(t.deadline), t.priority, t.isCompleted, _fmt(t.startTime),
      t.estimatedHours ?? '',
    ]),
  ];
}

// ---------------------------------------------------------------------------
// Import
// ---------------------------------------------------------------------------

class CsvImportResult {
  final int inserted;
  final int skipped;
  final List<String> errors;
  CsvImportResult({required this.inserted, required this.skipped, required this.errors});
}

Future<CsvImportResult> importTableFromCSV({
  required AppDatabase db,
  required String tableName,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (result == null || result.files.single.path == null) {
    return CsvImportResult(inserted: 0, skipped: 0, errors: ['No file selected']);
  }

  final file = File(result.files.single.path!);
  final csvString = await file.readAsString();
  final rows = const CsvToListConverter().convert(csvString);

  if (rows.length < 2) {
    return CsvImportResult(inserted: 0, skipped: 0, errors: ['CSV file is empty or has only headers']);
  }

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  final dataRows = rows.skip(1).toList();

  switch (tableName) {
    case 'clients':
      return _importClients(db, headers, dataRows);
    case 'projects':
      return _importProjects(db, headers, dataRows);
    case 'time_entries':
      return _importTimeEntries(db, headers, dataRows);
    case 'expenses':
      return _importExpenses(db, headers, dataRows);
    case 'invoices':
      return _importInvoices(db, headers, dataRows);
    case 'todos':
      return _importTodos(db, headers, dataRows);
    default:
      return CsvImportResult(inserted: 0, skipped: 0, errors: ['Unknown table: $tableName']);
  }
}

String _str(List<dynamic> row, List<String> headers, String col) {
  final i = headers.indexOf(col);
  if (i < 0 || i >= row.length) return '';
  return row[i].toString().trim();
}

int? _intN(List<dynamic> row, List<String> headers, String col) {
  final s = _str(row, headers, col);
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? _doubleN(List<dynamic> row, List<String> headers, String col) {
  final s = _str(row, headers, col);
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool _bool(List<dynamic> row, List<String> headers, String col) {
  final s = _str(row, headers, col).toLowerCase();
  return s == 'true' || s == '1';
}

Future<CsvImportResult> _importClients(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final name = _str(row, headers, 'name');
    if (name.isEmpty) {
      errors.add('Row ${i + 2}: missing name');
      skipped++;
      continue;
    }
    try {
      await db.into(db.clients).insert(ClientsCompanion.insert(
        name: name,
        email: Value(_str(row, headers, 'email').isEmpty ? null : _str(row, headers, 'email')),
        address: Value(_str(row, headers, 'address').isEmpty ? null : _str(row, headers, 'address')),
        currency: Value(_str(row, headers, 'currency').isEmpty ? 'USD' : _str(row, headers, 'currency')),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}

Future<CsvImportResult> _importProjects(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final name = _str(row, headers, 'name');
    final clientId = _intN(row, headers, 'clientId');
    final hourlyRate = _doubleN(row, headers, 'hourlyRate');

    if (name.isEmpty || clientId == null || hourlyRate == null) {
      errors.add('Row ${i + 2}: missing required field (name, clientId, or hourlyRate)');
      skipped++;
      continue;
    }
    try {
      final monthlyTimeLimit = _intN(row, headers, 'monthlyTimeLimit');
      final status = _str(row, headers, 'status');
      await db.into(db.projects).insert(ProjectsCompanion.insert(
        clientId: clientId,
        name: name,
        hourlyRate: hourlyRate,
        monthlyTimeLimit: Value(monthlyTimeLimit),
        status: Value(status.isEmpty ? 'Active' : status),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}

Future<CsvImportResult> _importTimeEntries(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final projectId = _intN(row, headers, 'projectId');
    final description = _str(row, headers, 'description');
    final startStr = _str(row, headers, 'startTime');
    final category = _str(row, headers, 'category');

    if (projectId == null || description.isEmpty || startStr.isEmpty || category.isEmpty) {
      errors.add('Row ${i + 2}: missing required field');
      skipped++;
      continue;
    }
    try {
      await db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
        projectId: projectId,
        description: description,
        startTime: _parse(startStr),
        endTime: Value(_parseNullable(_str(row, headers, 'endTime'))),
        category: category,
        isBillable: Value(_bool(row, headers, 'isBillable')),
        isBilled: Value(_bool(row, headers, 'isBilled')),
        isLogged: Value(_bool(row, headers, 'isLogged')),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}

Future<CsvImportResult> _importExpenses(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final description = _str(row, headers, 'description');
    final category = _str(row, headers, 'category');
    final amount = _doubleN(row, headers, 'amount');
    final dateStr = _str(row, headers, 'date');

    if (description.isEmpty || category.isEmpty || amount == null || dateStr.isEmpty) {
      errors.add('Row ${i + 2}: missing required field');
      skipped++;
      continue;
    }
    try {
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        description: description,
        projectId: Value(_intN(row, headers, 'projectId')),
        clientId: Value(_intN(row, headers, 'clientId')),
        category: category,
        amount: amount,
        date: _parse(dateStr),
        distance: Value(_doubleN(row, headers, 'distance')),
        costPerUnit: Value(_doubleN(row, headers, 'costPerUnit')),
        isBilled: Value(_bool(row, headers, 'isBilled')),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}

Future<CsvImportResult> _importInvoices(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final invoiceIdString = _str(row, headers, 'invoiceIdString');
    final clientId = _intN(row, headers, 'clientId');
    final issueDateStr = _str(row, headers, 'issueDate');
    final dueDateStr = _str(row, headers, 'dueDate');
    final totalAmount = _doubleN(row, headers, 'totalAmount');
    final status = _str(row, headers, 'status');

    if (invoiceIdString.isEmpty || clientId == null || issueDateStr.isEmpty ||
        dueDateStr.isEmpty || totalAmount == null || status.isEmpty) {
      errors.add('Row ${i + 2}: missing required field');
      skipped++;
      continue;
    }
    try {
      final notes = _str(row, headers, 'notes');
      final lineItemsJson = _str(row, headers, 'lineItemsJson');
      await db.into(db.invoices).insert(InvoicesCompanion.insert(
        invoiceIdString: invoiceIdString,
        clientId: clientId,
        issueDate: _parse(issueDateStr),
        dueDate: _parse(dueDateStr),
        totalAmount: totalAmount,
        status: status,
        notes: Value(notes.isEmpty ? null : notes),
        lineItemsJson: Value(lineItemsJson.isEmpty ? null : lineItemsJson),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}

Future<CsvImportResult> _importTodos(
    AppDatabase db, List<String> headers, List<List<dynamic>> rows) async {
  int inserted = 0, skipped = 0;
  final errors = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final title = _str(row, headers, 'title');
    final projectId = _intN(row, headers, 'projectId');
    final category = _str(row, headers, 'category');
    final deadlineStr = _str(row, headers, 'deadline');
    final priority = _str(row, headers, 'priority');
    final startTimeStr = _str(row, headers, 'startTime');

    if (title.isEmpty || projectId == null || category.isEmpty ||
        deadlineStr.isEmpty || priority.isEmpty || startTimeStr.isEmpty) {
      errors.add('Row ${i + 2}: missing required field');
      skipped++;
      continue;
    }
    try {
      final description = _str(row, headers, 'description');
      await db.into(db.todos).insert(TodosCompanion.insert(
        title: title,
        description: Value(description.isEmpty ? null : description),
        projectId: projectId,
        category: category,
        deadline: _parse(deadlineStr),
        priority: priority,
        isCompleted: Value(_bool(row, headers, 'isCompleted')),
        startTime: _parse(startTimeStr),
        estimatedHours: Value(_doubleN(row, headers, 'estimatedHours')),
      ));
      inserted++;
    } catch (e) {
      errors.add('Row ${i + 2}: $e');
      skipped++;
    }
  }
  return CsvImportResult(inserted: inserted, skipped: skipped, errors: errors);
}
