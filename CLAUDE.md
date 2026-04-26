# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
flutter pub get                 # install/refresh dependencies
dart run build_runner build     # regenerate lib/database/database.g.dart (run after editing tables in database.dart)
dart run build_runner build --delete-conflicting-outputs   # use when generated files are out of sync
flutter run                     # run on the default device
flutter run -d <linux|macos|windows|chrome|<deviceId>>     # target a specific platform
flutter analyze                 # static analysis (uses analysis_options.yaml -> flutter_lints)
flutter test                    # run all tests under test/
flutter test test/widget_test.dart -p "test name"          # run a single test by name
flutter build <apk|ios|linux|macos|windows|web>            # build a release artifact
```

Note: `test/widget_test.dart` is the Flutter starter "counter" stub and does not match the actual app (`MyApp` in `lib/main.dart` renders `MainScreen`, not a counter). It will fail if run as-is. Replace or delete it before relying on the test suite.

## Architecture

This is a Flutter desktop/mobile time-tracker. State lives entirely in a local SQLite database; there is no backend or auth layer. The UI is reactive — widgets subscribe to Drift streams and rebuild when the DB changes.

**Data layer — `lib/database/database.dart`**
- All tables (`Clients`, `Projects`, `TimeEntries`, `Expenses`, `Invoices`, `Todos`, `CompanySettings`) are defined in one file. Drift generates `database.g.dart` (~213KB) from this — never edit the `.g.dart` file by hand; edit `database.dart` and re-run build_runner.
- Foreign keys use `KeyAction.cascade` on delete throughout. Deleting a client cascades to its projects, time entries, expenses, and invoices.
- `schemaVersion` is currently 3. **Bump `schemaVersion` and add a branch to `MigrationStrategy.onUpgrade` whenever you change a table.** Existing example: v1→v2 added the `isLogged` column to `timeEntries`.
- The DB file is `app_tracker.sqlite` inside `getApplicationSupportDirectory()` (per-platform app support dir, opened via `LazyDatabase` + `NativeDatabase.createInBackground`).
- Invoice line items are not a relational table — they're serialized as JSON into `Invoices.lineItemsJson` via `lib/models/line_item.dart` (`lineItemsToJson` / `lineItemsFromJson`).

**Dependency injection — `lib/main.dart`**
- `AppDatabase` and `IdleService` are provided once at the root via `MultiProvider`. The `AppDatabase` provider owns the DB lifecycle (`dispose: (_, db) => db.close()`).
- Screens get the DB via `Provider.of<AppDatabase>(context)` and read/write directly — there is no repository or service layer between widgets and Drift.

**Reactive UI pattern**
- Lists and detail panes are `StreamBuilder<List<...>>` over `db.select(db.foo).watch()` (with `..where`, `..orderBy`, `..limit` chained on the SimpleSelectStatement). Mutations use `db.update(...).write(FooCompanion(...))` / `db.delete(...).go()` and the stream re-emits automatically.
- Use `XxxCompanion` (e.g. `TimeEntriesCompanion(isLogged: Value(true))`) for partial updates — wrap fields in `Value(...)`. Note `import 'package:drift/drift.dart' hide Column;` to avoid clashing with Flutter's `Column`.

**Active timer convention**
- A "running" timer is a `TimeEntry` with `endTime == null`. There is intended to be at most one. Stopping the timer = writing `endTime: Value(DateTime.now())`. The active-timer card and the recent-entries list both query on this null/not-null distinction (`time_tracker_screen.dart`).

**Idle detection — `lib/services/idle_service.dart` + root Listener in `main.dart`**
- The root `MaterialApp` is wrapped in a `Listener` that calls `IdleService.recordActivity()` on every pointer event. `IdleService.isIdle` is `true` when no activity for `idleThreshold` (default 5 min).
- `ActiveTimerCard` polls `IdleService` once per second; on the idle→active transition it shows a dialog offering Keep / Discard (rewind `startTime` past the idle gap) / Stop (set `endTime` to before the idle gap). When changing idle behavior, edit `_promptIdleAction` in `time_tracker_screen.dart`.

**Screens — `lib/screens/`**
- `main_screen.dart` is a `BottomNavigationBar` shell that switches between 8 top-level screens. The selected index maps positionally into both `_screens` and `_titles` — keep those two lists in sync when adding/removing tabs.
- Each domain follows a `xxx_screen.dart` (list) + `xxx_edit_screen.dart` (form) pair under `lib/screens/<domain>/`. Time tracker additionally has `add_entry_dialog.dart` (modal for the "+" FAB) and `edit_entry_screen.dart`.

**PDF generation — `lib/utils/pdf_generator.dart`**
- `generateAndShowInvoice` builds a `pw.Document` from an `Invoice`, `Client`, `CompanySetting`, and decoded `List<LineItem>`, then hands it to `Printing.layoutPdf`. Currency comes from `client.currency` via `NumberFormat.simpleCurrency`. Logo is loaded synchronously from `settings.logoPath` if set.

## Repository quirks

- `add_two_numbers.py` at the repo root is unrelated to the Flutter app — it's a stray Python file from an unrelated commit. Don't treat it as part of the project.
- The `README.md` "Clone the repo" URL points to `NicolasLobosDEV/time_tracker`, but the active GitHub remote in this workspace is `edualc-snoiltset13/time_tracker`. The README is a fork-of-origin artifact; trust the remote, not the README, for repo identity.
- Theme is dark-only (hardcoded `ThemeData.dark()` + deep-purple seed in `main.dart`). There is no light theme or theme switcher.
