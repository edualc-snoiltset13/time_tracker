// lib/database/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Define tables
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId =>
      integer().references(Clients, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get hourlyRate => real()();
  IntColumn get monthlyTimeLimit => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('Active'))();
}

class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get category => text()();
  BoolColumn get isBillable => boolean().withDefault(const Constant(true))();
  BoolColumn get isBilled => boolean().withDefault(const Constant(false))();
  // ADDED: New status for marking entries as logged in external platforms
  BoolColumn get isLogged => boolean().withDefault(const Constant(false))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  IntColumn get projectId =>
      integer().nullable().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId =>
      integer().nullable().references(Clients, #id, onDelete: KeyAction.cascade)();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  RealColumn get distance => real().nullable()();
  RealColumn get costPerUnit => real().nullable()();
  BoolColumn get isBilled => boolean().withDefault(const Constant(false))();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceIdString => text()();
  IntColumn get clientId =>
      integer().references(Clients, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get lineItemsJson => text().nullable()();
}

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get category => text()();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get priority => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startTime => dateTime()();
  RealColumn get estimatedHours => real().nullable()();
}

class CompanySettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get companyName => text()();
  TextColumn get companyAddress => text()();
  TextColumn get logoPath => text().nullable()();
  BoolColumn get showLetterhead => boolean().withDefault(const Constant(true))();
}

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text()(); // timer_stopped, deadline_approaching, time_limit_warning, weekly_summary, invoice_overdue, task_overdue, milestone_reached
  TextColumn get severity => text().withDefault(const Constant('info'))(); // info, warning, success, error
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isDismissed => boolean().withDefault(const Constant(false))();
  IntColumn get relatedEntityId => integer().nullable()(); // ID of related time entry, project, invoice, etc.
  TextColumn get relatedEntityType => text().nullable()(); // time_entry, project, invoice, todo, expense
  TextColumn get actionRoute => text().nullable()(); // Optional deep-link route to navigate to
  TextColumn get metadata => text().nullable()(); // JSON string for extra data
}

class NotificationPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get timerStopNotifications => boolean().withDefault(const Constant(true))();
  BoolColumn get deadlineReminders => boolean().withDefault(const Constant(true))();
  BoolColumn get timeLimitWarnings => boolean().withDefault(const Constant(true))();
  BoolColumn get weeklySummary => boolean().withDefault(const Constant(true))();
  BoolColumn get invoiceOverdueAlerts => boolean().withDefault(const Constant(true))();
  BoolColumn get taskOverdueAlerts => boolean().withDefault(const Constant(true))();
  BoolColumn get milestoneNotifications => boolean().withDefault(const Constant(true))();
  IntColumn get deadlineReminderMinutes => integer().withDefault(const Constant(60))(); // minutes before deadline
  IntColumn get timeLimitWarningPercent => integer().withDefault(const Constant(80))(); // percentage of time limit
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get vibrationEnabled => boolean().withDefault(const Constant(true))();
}


@DriftDatabase(tables: [Clients, Projects, TimeEntries, Expenses, Invoices, Todos, CompanySettings, AppNotifications, NotificationPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(timeEntries, timeEntries.isLogged);
        }
        if (from < 4) {
          await m.createTable(appNotifications);
          await m.createTable(notificationPreferences);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'app_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

