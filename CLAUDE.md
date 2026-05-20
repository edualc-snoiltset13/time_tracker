# CLAUDE.md - AI Assistant Guide for Time Tracker

## Project Overview

Time Tracker is a cross-platform Flutter application for freelancers and small teams to manage clients, projects, time entries, expenses, invoices, and tasks. It is a local-first app with no backend API — all data is stored in a local SQLite database.

## Tech Stack

- **Language:** Dart (SDK ^3.8.1)
- **Framework:** Flutter (cross-platform: Android, iOS, macOS, Windows, Linux, Web)
- **Database:** SQLite via [Drift](https://drift.simonbinder.eu/) ORM (reactive, type-safe)
- **State Management:** Provider (dependency injection of `AppDatabase` at app root)
- **PDF Generation:** `pdf` + `printing` packages
- **Charts:** `fl_chart`
- **Linting:** `flutter_lints` (standard Flutter recommended rules)

## Quick Commands

```bash
# Install dependencies
flutter pub get

# Run Drift code generation (required after database schema changes)
dart run build_runner build

# Run the app
flutter run

# Run static analysis
flutter analyze

# Run tests
flutter test

# Continuous code generation (watches for changes)
dart run build_runner watch
```

## Project Structure

```
lib/
├── main.dart                          # App entry point, Provider setup, theme
├── database/
│   ├── database.dart                  # Drift schema (7 tables), migrations
│   └── database.g.dart                # Generated Drift code (DO NOT EDIT)
├── models/
│   └── line_item.dart                 # LineItem model with JSON serialization
├── screens/
│   ├── main_screen.dart               # Bottom nav bar (8 tabs)
│   ├── home_screen.dart               # Tasks/To-Do list
│   ├── clients/
│   │   ├── clients_screen.dart        # Client list
│   │   └── client_edit_screen.dart    # Add/Edit client
│   ├── projects/
│   │   ├── projects_screen.dart       # Project list
│   │   └── project_edit_screen.dart   # Add/Edit project
│   ├── time_tracker/
│   │   ├── time_tracker_screen.dart   # Active timer & time entries
│   │   ├── add_entry_dialog.dart      # Manual entry creation dialog
│   │   └── edit_entry_screen.dart     # Edit time entry
│   ├── expenses/
│   │   ├── expenses_screen.dart       # Expense list
│   │   └── expense_edit_screen.dart   # Add/Edit expense
│   ├── invoices/
│   │   ├── invoices_screen.dart       # Invoice list
│   │   └── invoice_edit_screen.dart   # Add/Edit invoice (largest screen)
│   ├── todos/
│   │   └── todo_edit_screen.dart      # Add/Edit task
│   ├── reports/
│   │   └── reports_screen.dart        # Analytics & charts
│   └── settings/
│       └── settings_screen.dart       # Company settings
└── utils/
    └── pdf_generator.dart             # PDF invoice generation
```

## Architecture & Patterns

### Data Flow

```
UI (Screens) ← Provider → AppDatabase (Drift) → SQLite
```

- `AppDatabase` is injected at the app root via `Provider<AppDatabase>`.
- Screens access the database with `Provider.of<AppDatabase>(context)`.
- Drift provides reactive streams — use `.watch()` for live-updating queries in `StreamBuilder` widgets.
- No separate repository or service layer exists; screens query the database directly.

### Screen Pattern

Each feature follows this structure:
- **List screen** (`*_screen.dart`): displays items using `StreamBuilder` with Drift `.watch()` queries. Has a FAB to add new items.
- **Edit screen** (`*_edit_screen.dart`): form for creating/editing an item. Receives an optional existing item; `null` means "create new."

### Navigation

`MainScreen` uses a `BottomNavigationBar` with 8 tabs. Tab order:
1. Tasks To-Do
2. Time Tracker
3. Projects
4. Clients
5. Expenses
6. Invoices
7. Reports
8. Settings

Sub-screens (edit/add forms) are pushed via `Navigator.push` with `MaterialPageRoute`.

## Database

### Schema (version 3)

7 tables defined in `lib/database/database.dart`:

| Table | Key Fields | Notes |
|-------|-----------|-------|
| **Clients** | id, name, email, address, currency | Currency defaults to 'USD' |
| **Projects** | id, clientId (FK→Clients), name, hourlyRate, status | Cascade delete from Clients |
| **TimeEntries** | id, projectId (FK→Projects), startTime, endTime, isBillable, isBilled, isLogged | `endTime` nullable (running timer) |
| **Expenses** | id, projectId, clientId, amount, date, distance, costPerUnit, isBilled | Both FKs nullable |
| **Invoices** | id, invoiceIdString, clientId, issueDate, dueDate, totalAmount, status, lineItemsJson | Line items stored as JSON text |
| **Todos** | id, title, projectId, category, deadline, priority, isCompleted, estimatedHours | |
| **CompanySettings** | id, companyName, companyAddress, logoPath, showLetterhead | Singleton row |

### Migrations

- Current schema version: **3**
- Migration logic is in `AppDatabase.migration` (onUpgrade callback)
- When adding columns or tables, increment `schemaVersion` and add migration steps in `onUpgrade`
- All foreign keys use `onDelete: KeyAction.cascade`

### Code Generation

Drift uses code generation. After changing `database.dart`:
```bash
dart run build_runner build
```
This regenerates `database.g.dart`. **Never edit `database.g.dart` manually.**

### Models

- `LineItem` (`lib/models/line_item.dart`): not a Drift table — it's a plain Dart class serialized to/from JSON and stored in `Invoices.lineItemsJson`.
- Drift-generated data classes (e.g., `Client`, `Project`, `TimeEntry`) are in `database.g.dart`.

## Theme & Styling

- Dark theme based on `ThemeData.dark()` with `deepPurple` color scheme
- Scaffold background: `Color(0xFF1C1926)`
- Card color: black (`Color(0xFF000000)`)
- Bottom nav background: `Color(0xFF1E1E1E)`
- Selected nav item: `Colors.tealAccent`
- FAB: `Colors.deepPurple`

## Key Conventions

- **Widgets use `const` constructors** where possible (`const MyWidget({super.key})`)
- **File naming:** `snake_case.dart` — one primary widget/class per file
- **Screen organization:** feature-based folders under `lib/screens/`
- **Database access:** always through `Provider.of<AppDatabase>(context)` — no global singletons
- **Date formatting:** uses `intl` package (`DateFormat`)
- **Currency formatting:** `NumberFormat.simpleCurrency(name: client.currency)`
- **No .env files or secrets** — all configuration lives in the database (`CompanySettings` table)
- **No backend/API** — fully local-first with SQLite storage

## Testing

- Test runner: `flutter test`
- Tests located in `test/` directory
- Currently minimal — only a default widget smoke test exists (`test/widget_test.dart`)
- Uses `flutter_test` package

## Common Tasks

### Adding a New Feature Screen

1. Create a folder under `lib/screens/<feature>/`
2. Add the list screen (`<feature>_screen.dart`) and edit screen (`<feature>_edit_screen.dart`)
3. If a new table is needed, add it to `lib/database/database.dart`, increment `schemaVersion`, add migration logic, then run `dart run build_runner build`
4. Register the screen in `lib/screens/main_screen.dart` (add to `_screens` list, `_titles`, and `BottomNavigationBarItem`)

### Adding a Database Column

1. Add the column in the table class in `lib/database/database.dart`
2. Increment `schemaVersion`
3. Add migration logic in `onUpgrade` (e.g., `await m.addColumn(tableName, tableName.columnName)`)
4. Run `dart run build_runner build`

### Modifying the Invoice PDF

Edit `lib/utils/pdf_generator.dart`. The generator uses the `pdf` package's widget system (similar to Flutter widgets but prefixed with `pw.`).
