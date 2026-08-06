// lib/database/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Define tables for Divine Life - Religious App
class Prayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get type => text().withDefault(const Constant('Personal'))(); // Personal, Gratitude, Intercession, Praise
  TextColumn get intention => text().nullable()();
  DateTimeColumn get createdDate => dateTime()();
  DateTimeColumn get prayedDate => dateTime().nullable()();
  IntColumn get prayerCount => integer().withDefault(const Constant(1))();
  BoolColumn get isAnswered => boolean().withDefault(const Constant(false))();
  TextColumn get answerNotes => text().nullable()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
}

class DailyVerse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get book => text()();
  TextColumn get chapter => text()();
  TextColumn get verses => text()();
  TextColumn get text => text()();
  TextColumn get translation => text().withDefault(const Constant('KJV'))();
  DateTimeColumn get readDate => dateTime().nullable()();
  TextColumn get reflection => text().nullable()();
  RealColumn get engagementScore => real().withDefault(const Constant(0))();
}

class Meditations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get topic => text()(); // Mindfulness, Breath, Gratitude, Scripture
  TextColumn get description => text().nullable()();
  DateTimeColumn get sessionDate => dateTime()();
  IntColumn get durationMinutes => integer()();
  TextColumn get difficulty => text().withDefault(const Constant('Beginner'))();
  TextColumn get notes => text().nullable()();
  RealColumn get peaceScore => real().withDefault(const Constant(5))();
  BoolColumn get isGuided => boolean().withDefault(const Constant(false))();
}

class DailyDevotionals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get devotionalDate => dateTime()();
  TextColumn get topic => text()();
  TextColumn get scripture => text()();
  TextColumn get message => text()();
  TextColumn get application => text().nullable()();
  TextColumn get prayer => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedDate => dateTime().nullable()();
}

class SpiritualHabits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitName => text()(); // Prayer, Meditation, Scripture Reading, Fasting, Service
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get frequencyPerWeek => integer().withDefault(const Constant(1))();
}

class Reflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get journalDate => dateTime()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get mood => text().nullable()(); // Peaceful, Grateful, Challenged, Hopeful, Joyful
  TextColumn get gratitudeItems => text().nullable()();
  RealColumn get faithScore => real().withDefault(const Constant(5))();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(true))();
}

class BibleStudy extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get book => text()();
  TextColumn get chapter => text()();
  DateTimeColumn get studyDate => dateTime()();
  TextColumn get passage => text()();
  TextColumn get observations => text()();
  TextColumn get interpretations => text()();
  TextColumn get applications => text()();
  IntColumn get timeSpentMinutes => integer()();
  TextColumn get keyTakeaway => text().nullable()();
}

class Testimonies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get story => text()();
  DateTimeColumn get dateCreated => dateTime()();
  TextColumn get theme => text().nullable()(); // Healing, Provision, Guidance, Transformation
  RealColumn get impactScore => real().withDefault(const Constant(0))();
  IntColumn get shareCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPublic => boolean().withDefault(const Constant(true))();
}

class Blessings extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get blessingDate => dateTime()();
  TextColumn get description => text()();
  TextColumn get category => text().nullable()(); // Health, Relationships, Provision, Spiritual, Family
  TextColumn get gratitudeNote => text().nullable()();
  RealColumn get gratitudeLevel => real().withDefault(const Constant(5))();
}

class FaithGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get goal => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get category => text()(); // Spiritual Growth, Service, Learning, Practice
  IntColumn get progressPercentage => integer().withDefault(const Constant(0))();
  TextColumn get steps => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

class CommunityPrayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get request => text()();
  TextColumn get submitter => text().nullable()();
  DateTimeColumn get submissionDate => dateTime()();
  IntColumn get prayerCount => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()(); // Health, Family, Work, Guidance
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}


@DriftDatabase(tables: [Prayers, DailyVerse, Meditations, DailyDevotionals, SpiritualHabits, Reflections, BibleStudy, Testimonies, Blessings, FaithGoals, CommunityPrayers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // FIX: Incremented schema version to 3

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Fresh start for religious app
        await m.deleteTable('clients');
        await m.deleteTable('projects');
        await m.deleteTable('time_entries');
        await m.deleteTable('expenses');
        await m.deleteTable('invoices');
        await m.deleteTable('todos');
        await m.deleteTable('company_settings');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'divine_life.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

