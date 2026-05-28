# CLAUDE.md

## Project Overview

Time Tracker is a cross-platform Flutter application for freelancers and small teams. It provides time tracking, client/project management, expense tracking, task management, PDF invoice generation, and analytics reporting. All data is stored locally in SQLite — there is no backend API or cloud sync.

## Tech Stack

- **Language:** Dart (SDK ^3.8.1)
- **Framework:** Flutter (cross-platform: Android, iOS, macOS, Windows, Linux, Web)
- **State Management:** Provider
- **Database:** SQLite via Drift ORM (formerly Moor)
- **PDF:** `pdf` + `printing` packages
- **Charts:** `fl_chart`
- **Linting:** `flutter_lints` v6.0.0

## Project Structure

```
lib/
├── main.dart                    # App entry point, Provider setup, theme config
├── database/
│   ├── database.dart            # Drift schema (7 tables) and migration logic
│   └── database.g.dart          # Auto-generated Drift code (DO NOT EDIT)
├── models/
│   └── line_item.dart           # Invoice line item model with JSON serialization
├── screens/
│   ├── main_screen.dart         # Bottom nav bar with 8 tabs
│   ├── home_screen.dart         # Tasks/to-do list (default landing screen)
│   ├── clients/                 # Client CRUD screens
│   ├── projects/                # Project CRUD screens
│   ├── time_tracker/            # Time entry management + active timer
│   ├── expenses/                # Expense tracking with mileage support
│   ├── invoices/                # Invoice management with line items
│   ├── reports/                 # Analytics charts by time period
│   ├── settings/                # Company info, logo, preferences
│   └── todos/                   # Task edit screen
└── utils/
    └── pdf_generator.dart       # PDF invoice generation
test/
    └── widget_test.dart         # Basic smoke test
```

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (required after changing database schema)
dart run build_runner build

# Run the app
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d macos           # macOS desktop

# Static analysis / linting
flutter analyze

# Run tests
flutter test

# Build for release
flutter build apk              # Android
flutter build ios               # iOS
flutter build web               # Web
flutter build macos             # macOS
flutter build linux             # Linux
flutter build windows           # Windows
```

## Database

- **ORM:** Drift v2.18.0 with code generation
- **Schema version:** 3 (see `database.dart:99`)
- **Storage:** `app_tracker.sqlite` in application support directory
- **7 tables:** Clients, Projects, TimeEntries, Expenses, Invoices, Todos, CompanySettings
- Foreign keys use `KeyAction.cascade` for deletion
- Generated file is `database.g.dart` — never edit manually

### Schema Changes

1. Modify table definitions in `lib/database/database.dart`
2. Increment `schemaVersion` in `AppDatabase`
3. Add migration logic in `MigrationStrategy.onUpgrade`
4. Run `dart run build_runner build` to regenerate `database.g.dart`

## Architecture & Patterns

### State Management
- `AppDatabase` is provided at the root via `Provider<AppDatabase>`
- Screens access the database with: `Provider.of<AppDatabase>(context, listen: false)`
- Reactive UI updates use `StreamBuilder` with Drift's `.watch()` streams

### Screen Organization
Each feature module follows a consistent pattern:
- `*_screen.dart` — list/display view
- `*_edit_screen.dart` — create/edit form (dialog or full screen)

### Forms
- Standard Flutter `Form` with `GlobalKey<FormState>` and `TextFormField` validators
- Confirmation dialogs for destructive actions (delete)
- `ScaffoldMessenger.showSnackBar()` for user feedback

### Database Access
- Use `Companion` objects for inserts/updates (e.g., `ClientsCompanion`, `ProjectsCompanion`)
- Queries use Drift's `.where()`, `.orderBy()`, `.limit()` builders
- Reactive streams via `.watch()` returning `Stream<List<T>>`
- Joins use `TypedResult`

## Coding Conventions

- **Classes:** PascalCase (`TimeTrackerScreen`, `ClientEditScreen`)
- **Methods/variables:** camelCase (`_startTimerFromTodo`, `_saveEntry`)
- **Private members:** underscore prefix (`_categories`, `_selectedIndex`)
- **Database tables:** PascalCase plural (`Clients`, `TimeEntries`)
- **Imports:** use `package:time_tracker/...` (package imports, not relative)
- **Async safety:** always check `context.mounted` before calling `setState` or showing UI after an `await`

## Predefined Categories

- **Time entries:** Client Communication, Meetings, Operations, Freelancer Support, Resource Management, Run Closure, Run Preparation, Test Management
- **Expenses:** Day Rate, Lodging, Meals, Mileage, Other
- **Invoice statuses:** Draft, Sent, Paid
- **Task priorities:** P1, P2, P3

## Theme

The app uses a dark theme with `deepPurple` as the primary seed color and a dark scaffold background (`#1C1926`). The bottom nav uses `tealAccent` for the selected item.

## Important Notes

- `database.g.dart` is auto-generated — always run `dart run build_runner build` after schema changes
- No CI/CD pipeline is configured
- Test coverage is minimal (single smoke test)
- The app is local-only with no network calls or remote APIs
- PDF generation uses Google Fonts (OpenSans) loaded at runtime via `PdfGoogleFonts`
