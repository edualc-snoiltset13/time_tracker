# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Cross-platform Flutter time tracking and invoicing app (Android, iOS, Windows, macOS, Linux, Web). Dart SDK `^3.8.1`. Local-only persistence via SQLite (Drift). No backend.

## Common commands

```sh
flutter pub get                          # install dependencies
dart run build_runner build              # regenerate lib/database/database.g.dart
dart run build_runner build --delete-conflicting-outputs   # if generation fails on stale files
dart run build_runner watch              # auto-regenerate while iterating on schema
flutter run                              # run on the default device
flutter run -d <device-id>               # run on a specific device (flutter devices to list)
flutter analyze                          # lint with flutter_lints (see analysis_options.yaml)
flutter test                             # run all widget tests
flutter test test/widget_test.dart       # run a single test file
flutter test --name "<substring>"        # run a single test by name
flutter build <apk|ios|windows|macos|linux|web>
```

After any change to a `Table` class in `lib/database/database.dart`, rerun `build_runner` before `flutter run` — Drift will not compile without an up-to-date `database.g.dart`.

The existing `test/widget_test.dart` is the stale Flutter template (asserts a counter that no longer exists) and will fail; replace it rather than chasing the failure when adding real tests.

## Architecture

### Entry point and dependency injection
`lib/main.dart` wraps the app in a `MultiProvider` exposing two long-lived singletons:
- `AppDatabase` (Drift) — disposed on app shutdown.
- `IdleService` — see "Idle detection" below.

The root widget is a `Listener` that funnels every pointer event into `IdleService.recordActivity()`, so idle detection works globally without each screen wiring it up.

`MainScreen` (`lib/screens/main_screen.dart`) is the persistent shell: a `BottomNavigationBar` switches between 8 feature screens kept in a `List<Widget>` indexed by `_selectedIndex`. There is no router — navigation into edit screens uses `Navigator.push(MaterialPageRoute(...))`.

### Data layer (Drift / SQLite)
`lib/database/database.dart` declares all tables and the `AppDatabase` class; `database.g.dart` is generated and **must not be edited by hand**. Schema:

- `Clients` → `Projects` → `TimeEntries` (all with `onDelete: KeyAction.cascade`)
- `Expenses` (nullable FKs to Project and Client)
- `Todos` (FK to Project; a "Start Timer" action on the home screen creates a `TimeEntry` from a `Todo`)
- `Invoices` — `lineItemsJson` is a JSON-serialized `List<LineItem>` (see `lib/models/line_item.dart`); use `lineItemsToJson` / `lineItemsFromJson` for round-tripping rather than touching the column directly.
- `CompanySettings` — singleton-style row for company name/address/logo used by the PDF generator.

`schemaVersion` is currently `3`. When you change any table, **bump `schemaVersion` and add a branch to `MigrationStrategy.onUpgrade`**. The existing `from < 2` branch (adding `TimeEntries.isLogged`) shows the pattern. Drift will not silently reshape an existing user's DB.

`TimeEntries` has three independent boolean flags that look similar but mean different things:
- `isBillable` — should this time appear on an invoice at all?
- `isBilled` — has it already been included in a generated invoice? (Drives the green/red card tint on the time tracker screen.)
- `isLogged` — externally logged elsewhere (e.g. client system); UI-only toggle, no business logic depends on it.

An "active timer" is a `TimeEntry` row with `endTime == null`. Queries that look for it use `..where((t) => t.endTime.isNull())`. Only one is expected at a time — `HomeScreen._startTimerFromTodo` enforces this before inserting.

### State management
There is no ChangeNotifier/Bloc/Riverpod layer. UI reactivity comes from Drift streams: screens call `db.select(...).watch()` (or `.join(...).watch()`) and pipe the stream straight into a `StreamBuilder`. Writes go through `db.update(...).write(...)`, `db.into(...).insert(...)`, or `db.delete(...).go()` and the streams re-emit automatically. Keep this pattern — don't introduce a parallel state cache.

### Idle detection
`IdleService` (`lib/services/idle_service.dart`) holds a single `_lastActivity` timestamp and exposes `isIdle` (defaults to 5 minutes without input). `ActiveTimerCard` in `time_tracker_screen.dart` polls it on a 1-second `Timer`; when the user returns from idle it prompts for **keep / discard / stop**, then mutates the active `TimeEntry`'s `startTime` (discard) or `endTime` (stop) accordingly. This is the only place idle state affects data — don't reimplement it per-screen.

### Feature screens
Each feature lives under `lib/screens/<feature>/` and typically contains a list screen plus an edit screen (e.g. `clients_screen.dart` + `client_edit_screen.dart`). They follow the same shape: `StreamBuilder` over a Drift query → `ListView.builder` → `Dismissible`/edit-on-tap rows. New features should match this layout.

### PDF invoices
`lib/utils/pdf_generator.dart` builds invoice PDFs using `pdf` + `printing` and Google Fonts (Open Sans). It consumes an `Invoice`, the related `Client`, the singleton `CompanySetting`, and a decoded `List<LineItem>`. Currency is formatted from `client.currency` via `NumberFormat.simpleCurrency`. The letterhead block is conditional on `CompanySetting.showLetterhead`.

## Conventions

- App-wide theme is dark, deep-purple seeded; set in `MyApp.build` in `main.dart`. Use `Theme.of(context).colorScheme.error` etc. rather than hardcoding colors when extending UI.
- Date/currency formatting goes through the `intl` package (`DateFormat`, `NumberFormat`). Don't hand-roll formatting.
- Use `package:time_tracker/...` absolute imports (matches existing files); avoid long relative paths.
- IDs are auto-increment integers from Drift; `uuid` is in the dependency list but not currently used — prefer the DB-generated id for new entities unless there's a reason otherwise.

## Notes / gotchas

- `add_two_numbers.py` at the repo root is unrelated to the Flutter app — a stray Python sample. Don't treat it as part of the build.
- The README's contribution section references a different upstream (`NicolasLobosDEV/time_tracker`); this fork pushes to `edualc-snoiltset13/time_tracker`.
- Web/desktop platform folders exist (`web/`, `windows/`, `macos/`, `linux/`) but the database path uses `getApplicationSupportDirectory()` from `path_provider`, so the SQLite file location differs per platform — keep that in mind when debugging "missing data" reports.
