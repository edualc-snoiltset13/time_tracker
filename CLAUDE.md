# CLAUDE.md - AI Assistant Guide for Time Tracker

## Project Overview

Time Tracker is a cross-platform Flutter application for freelancers and small teams to track time, manage clients/projects, handle expenses, generate invoices, and manage tasks. It runs on Android, iOS, Windows, macOS, Linux, and Web.

## Quick Reference

```bash
# Install dependencies
flutter pub get

# Generate Drift database code (required after schema changes)
dart run build_runner build

# Run the app
flutter run

# Run tests
flutter test

# Static analysis
flutter analyze

# Format code
dart format .
```

## Project Structure

```
lib/
├── main.dart              # App entry point, Provider setup, theme config
├── database/
│   ├── database.dart      # Drift table definitions + AppDatabase class
│   └── database.g.dart    # Generated code (DO NOT EDIT)
├── models/
│   └── line_item.dart     # LineItem data model (for invoices)
├── screens/
│   ├── main_screen.dart   # Bottom nav bar + tab routing
│   ├── home_screen.dart   # Dashboard / home tab
│   ├── clients/           # Client management screens
│   ├── projects/          # Project management screens
│   ├── time_tracker/      # Time tracking + timer screens
│   ├── expenses/          # Expense tracking screens
│   ├── invoices/          # Invoice management screens
│   ├── reports/           # Reports & analytics screens
│   ├── todos/             # Task/todo management screens
│   └── settings/          # Company settings screens
├── utils/
│   └── pdf_generator.dart # PDF invoice generation
test/
├── widget_test.dart       # Widget tests (currently template only)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart SDK ^3.8.1) |
| Database | SQLite via Drift ORM (^2.18.0) |
| State Management | Provider (^6.1.2) |
| Code Generation | build_runner + drift_dev |
| PDF | pdf (^3.10.8) + printing (^5.12.0) |
| Charts | fl_chart (^1.0.0) |
| Linting | flutter_lints (^6.0.0) |

## Architecture & Patterns

### State Management
- **Provider** injects `AppDatabase` at the widget tree root in `main.dart`
- Access the database anywhere via `Provider.of<AppDatabase>(context)`
- No separate repository or service layer; screens query the database directly

### Database (Drift)
- All 7 tables defined in `lib/database/database.dart`
- Tables: `Clients`, `Projects`, `TimeEntries`, `Expenses`, `Invoices`, `Todos`, `CompanySettings`
- Schema version: **3** (migrations handle upgrades from v1)
- Foreign keys use **cascade delete** (`KeyAction.cascade`)
- Database file: `app_tracker.sqlite` in platform app support directory
- After changing table definitions, regenerate with: `dart run build_runner build`

### Reactive UI
- Screens use `StreamBuilder` with Drift's `.watch()` for real-time updates
- Active timers detected by `endTime == null` on `TimeEntries`

### Navigation
- `MainScreen` uses `BottomNavigationBar` with 8 tabs
- Sub-screens use `MaterialPageRoute` push navigation
- Always check `mounted` before navigation after async operations

## Coding Conventions

### Naming
- **Files:** `snake_case.dart` (e.g., `home_screen.dart`, `pdf_generator.dart`)
- **Classes:** `PascalCase` (e.g., `TimeTrackerScreen`, `AppDatabase`)
- **Variables/methods:** `camelCase` (e.g., `startTime`, `isBillable`)
- **Private members:** prefix with `_` (e.g., `_selectedIndex`)

### File Organization
- Feature-based folders under `lib/screens/`
- Each feature folder typically has a list screen and edit/add screens
- Database schema and generated code in `lib/database/`
- Shared data models in `lib/models/`
- Utility functions in `lib/utils/`

### Widget Patterns
- `StatelessWidget` for display-only screens
- `StatefulWidget` for interactive screens with forms or timers
- Confirmation dialogs before destructive actions (delete)
- `SnackBar` for user feedback notifications
- `Dismissible` widgets for swipe-to-delete

### Theme
- Dark theme with deep purple primary color
- Scaffold background: `Color.fromARGB(255, 28, 25, 38)`
- Card color: black
- Teal accent for selected navigation items

## Database Schema

| Table | Key Columns | Notes |
|-------|-------------|-------|
| Clients | id, name, email, address, currency | Default currency: USD |
| Projects | id, clientId (FK), name, hourlyRate, status | Status: Active/Inactive |
| TimeEntries | id, projectId (FK), startTime, endTime, isBillable, isBilled, isLogged | endTime=null means timer is running |
| Expenses | id, projectId (FK), clientId (FK), amount, distance, costPerUnit | distance/costPerUnit for mileage |
| Invoices | id, invoiceIdString, clientId (FK), lineItemsJson | Line items stored as JSON |
| Todos | id, projectId (FK), title, priority, deadline, isCompleted | Priority: P1/P2/P3 |
| CompanySettings | id, companyName, companyAddress, logoPath, showLetterhead | Single row for settings |

## Common Development Tasks

### Adding a New Table
1. Define the table class in `lib/database/database.dart`
2. Add it to the `@DriftDatabase(tables: [...])` annotation
3. Increment `schemaVersion` and add migration logic in `migration`
4. Run `dart run build_runner build` to regenerate
5. Create corresponding screen(s) in `lib/screens/`

### Adding a Column to an Existing Table
1. Add the column definition to the table class
2. Increment `schemaVersion`
3. Add migration in `onUpgrade` using `m.addColumn()`
4. Run `dart run build_runner build`

### Creating a New Screen
1. Create a new folder under `lib/screens/` if it's a new feature
2. Follow existing patterns: use `StreamBuilder` + `.watch()` for lists
3. Access database via `Provider.of<AppDatabase>(context)`
4. Add navigation from `MainScreen` or parent screens

## Important Notes

- **Generated files:** Never edit `database.g.dart` - it is regenerated by build_runner
- **No backend API:** This is a fully local-first app; all data is in SQLite
- **No CI/CD:** No GitHub Actions or automated pipelines configured
- **No .env files:** No environment-specific configuration
- **Test coverage:** Minimal - only a template widget test exists
- **Platform code:** Standard Flutter boilerplate in `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` directories; rarely needs changes
