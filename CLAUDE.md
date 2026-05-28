# CLAUDE.md

## Project Overview

Time Tracker is a cross-platform Flutter application for freelancers and small teams. It provides time tracking, expense management, invoicing with PDF generation, client/project management, task to-dos, and reporting with charts. It runs on Android, iOS, Windows, macOS, Linux, and Web.

- **Language:** Dart (SDK ^3.8.1)
- **Framework:** Flutter with Material Design 3 (dark theme)
- **Version:** 1.0.0+1
- **License:** MIT

## Quick Reference

```bash
# Install dependencies
flutter pub get

# Generate Drift database code (required after schema changes)
dart run build_runner build

# Run the app
flutter run

# Run static analysis
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk        # Android
flutter build ios         # iOS
flutter build web         # Web
flutter build windows     # Windows
flutter build macos       # macOS
flutter build linux       # Linux
```

## Project Structure

```
lib/
  main.dart                    # App entry point, Provider setup, theme config
  database/
    database.dart              # Drift ORM schema (7 tables) and migrations
    database.g.dart            # Generated Drift code (DO NOT edit manually)
  models/
    line_item.dart             # Invoice line item model with JSON serialization
  screens/
    main_screen.dart           # Bottom navigation hub (8 tabs)
    home_screen.dart           # To-do list with timer integration
    clients/                   # Client CRUD screens
    projects/                  # Project management screens
    time_tracker/              # Timer, add/edit time entries
    expenses/                  # Expense tracking screens
    invoices/                  # Invoice list and editor
    reports/                   # Charts and analytics
    settings/                  # Company branding config
    todos/                     # To-do editing screen
  utils/
    pdf_generator.dart         # PDF invoice generation
test/
  widget_test.dart             # Widget tests (currently placeholder)
```

## Architecture

### State Management
- **Provider** supplies a singleton `AppDatabase` instance at the app root (`lib/main.dart`)
- Database access throughout the app: `Provider.of<AppDatabase>(context, listen: false)`

### Database
- **Drift ORM** over SQLite (`app_tracker.sqlite` in app support directory)
- Schema version: **3** (migrations in `database.dart` `MigrationStrategy`)
- 7 tables: `Clients`, `Projects`, `TimeEntries`, `Expenses`, `Invoices`, `Todos`, `CompanySettings`
- Foreign keys use `KeyAction.cascade` for delete propagation
- Reactive UI updates via Drift `watch()` queries consumed by `StreamBuilder`

### Navigation
- Single `MainScreen` with `BottomNavigationBar` switching between 8 feature tabs
- Screen pairs: list screen + edit/detail screen per feature (e.g., `clients_screen.dart` + `client_edit_screen.dart`)

### Theme
- Dark theme with Deep Purple primary color
- Background: `Color.fromARGB(255, 28, 25, 38)`
- Cards: Black `Color.fromARGB(255, 0, 0, 0)`
- Navigation selected items: Teal Accent

## Database Schema Changes

When modifying the database schema in `lib/database/database.dart`:

1. Update the table definition
2. Increment `schemaVersion` in `AppDatabase`
3. Add migration logic in `MigrationStrategy.onUpgrade`
4. Regenerate code: `dart run build_runner build`

The generated file `database.g.dart` must never be edited manually.

## Code Conventions

### Naming
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/functions:** `camelCase`
- **Private members:** leading underscore (`_selectedIndex`, `_buildHeader()`)

### Patterns
- Screens are organized in feature subdirectories under `lib/screens/`
- Forms use `GlobalKey<FormState>` for validation
- Destructive actions require confirmation dialogs
- Swipe-to-delete via `Dismissible` widgets
- Async database operations use `Future` and `Stream`
- Invoice line items stored as JSON string in `lineItemsJson` column

### Linting
- Uses `flutter_lints` (package:flutter_lints/flutter.yaml)
- Run `flutter analyze` to check for issues
- No custom lint rules are configured beyond the defaults

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `drift` / `drift_dev` | Reactive SQLite ORM + code generation |
| `sqlite3_flutter_libs` | SQLite native libraries |
| `provider` | State management (DI for database) |
| `pdf` / `printing` | PDF invoice generation and printing |
| `fl_chart` | Charts in reports screen |
| `intl` | Date and currency formatting |
| `path_provider` | Platform-specific directory paths |
| `file_picker` / `image_picker` | File and image selection |
| `uuid` | Unique ID generation for invoices |
| `build_runner` | Code generation runner (dev) |

## Testing

Tests live in `test/`. The current test file (`widget_test.dart`) is a Flutter template placeholder and does not test actual app functionality. Run with `flutter test`.

## Things to Know

- No CI/CD pipelines are configured
- No Docker configuration exists
- No backend API -- all data is local SQLite
- The `database.g.dart` file is ~280KB of generated code; always regenerate, never hand-edit
- The app has no custom fonts or bundled assets beyond Material Icons
- `pubspec.yaml` has `publish_to: 'none'` (private package)
