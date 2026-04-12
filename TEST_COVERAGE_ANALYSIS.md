# Test Coverage Analysis

## Current State

The project has **virtually zero meaningful test coverage**. The sole test file
(`test/widget_test.dart`) contains a default Flutter counter-app smoke test that
does not correspond to the actual application. It tests a counter widget that
does not exist in this codebase.

| Metric | Value |
|---|---|
| Source files (lib/) | 21 Dart files (~7,300 lines including generated code) |
| Test files (test/) | 1 file (default template, non-functional) |
| Meaningful test coverage | **0%** |
| Database tables | 7 (Clients, Projects, TimeEntries, Expenses, Invoices, Todos, CompanySettings) |
| Screens | 12 |
| Utility modules | 1 (PDF generator) |
| Models | 1 (LineItem with JSON serialization) |

---

## Priority 1 — Unit Tests for Pure Business Logic

These are the highest-value, lowest-effort tests. They exercise pure functions
and model logic with no Flutter or database dependencies.

### 1.1 `LineItem` model (`lib/models/line_item.dart`)

The `LineItem` class and its helper functions contain serialization logic that
the invoice system depends on. Bugs here silently corrupt stored invoice data.

**What to test:**
- `LineItem.total` getter — verify `quantity * unitPrice` for normal, zero, and
  negative values.
- `LineItem.toJson()` / `LineItem.fromJson()` — round-trip serialization.
- `lineItemsToJson()` / `lineItemsFromJson()` — list serialization with empty
  lists, single items, and multiple items.
- Edge cases: very large numbers (floating-point precision), `fromJson` with
  `int` values instead of `double` (the code handles this via `as num`).

**Estimated effort:** Small — no mocking needed.

### 1.2 Duration formatting (`lib/screens/time_tracker/time_tracker_screen.dart`)

The `_formatDuration` method (duplicated in `_TimeTrackerScreenState` and
`_ActiveTimerCardState`) converts a `Duration` into `HH:MM:SS` format. This is
currently a private method embedded in widget state, which makes it untestable
without refactoring.

**What to test:**
- Zero duration → `"00:00:00"`
- Sub-minute durations → correct seconds
- Multi-hour durations → correct hour display
- Durations over 99 hours (3+ digit hours)

**Recommended refactor:** Extract to a top-level or utility function.

### 1.3 Date range calculations (`lib/screens/reports/reports_screen.dart`)

The `_getDateRange` method computes date ranges for `thisWeek`, `lastWeek`,
`lastMonth`, and `thisYear`. Date math is notoriously error-prone, especially
around month/year boundaries.

**What to test:**
- Each `TimePeriod` variant returns correct start/end dates.
- Edge cases: first day of the year, last day of the year, leap years, months
  with 28/30/31 days.
- Week boundaries (Monday-based weeks).

**Recommended refactor:** Extract to a standalone function that accepts a "now"
parameter for deterministic testing.

### 1.4 Priority color mapping (`lib/screens/home_screen.dart`)

The `_getPriorityColor` method maps priority strings (`P1`, `P2`, `P3`) to
colors.

**What to test:**
- Known priorities return expected colors.
- Unknown priority string falls through to default grey.

**Recommended refactor:** Extract to a utility function.

### 1.5 Mileage calculation (`lib/screens/expenses/expense_edit_screen.dart`)

The `_calculateMileageTotal` method computes `distance * costPerUnit`.

**What to test:**
- Normal multiplication.
- Empty/invalid input defaults to 0.
- Result formatting (2 decimal places).

**Recommended refactor:** Extract the calculation to a pure function.

### 1.6 Weekly total calculation (`lib/screens/time_tracker/time_tracker_screen.dart`)

The `_buildWeeklyTotal` method filters time entries to the current week and sums
durations. The filtering logic (lines 159-165) is worth testing independently.

**What to test:**
- Entries within the current week are included.
- Entries from previous/next weeks are excluded.
- Entries without an `endTime` are excluded.
- Week boundary (Monday 00:00 to Sunday 23:59).

**Recommended refactor:** Extract the filtering and summing into a testable
function.

---

## Priority 2 — Database Layer Tests

These tests verify that the Drift database schema, queries, and migrations work
correctly. They require an in-memory database but no Flutter widget tree.

### 2.1 CRUD operations for all tables

Each of the 7 tables should have tests for create, read, update, and delete.

**What to test per table:**
- Insert a record and read it back.
- Update a field and verify the change persists.
- Delete a record and verify it is gone.
- Default values are applied (e.g., `currency` defaults to `'USD'`,
  `isBillable` defaults to `true`, `isLogged` defaults to `false`).

**Tables:** Clients, Projects, TimeEntries, Expenses, Invoices, Todos,
CompanySettings.

### 2.2 Cascade delete behavior

The schema uses `onDelete: KeyAction.cascade` on several foreign keys. This is
critical — deleting a client should cascade-delete their projects, which should
cascade-delete time entries and expenses.

**What to test:**
- Delete a Client → all their Projects are deleted.
- Delete a Project → all its TimeEntries and Expenses are deleted.
- Delete a Client → Projects → TimeEntries chain cascade.

### 2.3 Foreign key constraints

**What to test:**
- Inserting a Project with a non-existent `clientId` should fail.
- Inserting a TimeEntry with a non-existent `projectId` should fail.

### 2.4 Migration logic (`database.dart` lines 103-118)

The database is at schema version 3 with migration logic for version 1→2.

**What to test:**
- Fresh database creation (version 3) succeeds.
- Migration from version 1 → 3 adds the `isLogged` column.
- Migration from version 2 → 3 succeeds without errors.

### 2.5 Complex queries

Several screens perform join queries that should be tested at the database level.

**What to test:**
- Projects joined with Clients (used by ProjectsScreen, AddEntryDialog).
- TimeEntries joined with Projects filtered by client (used by invoice
  creation).
- Expenses filtered by client or project (used by ExpensesScreen).
- Todos joined with Projects (used by HomeScreen).
- Unbilled time entries within a date range (used by InvoiceEditScreen).

**Estimated effort:** Medium — requires `drift` in-memory database setup.

---

## Priority 3 — Widget Tests

These tests verify that screens render correctly and handle user interactions.
They require the Flutter test framework and typically a mocked database.

### 3.1 `MainScreen` navigation

**What to test:**
- All 8 navigation items are rendered.
- Tapping each item switches to the correct screen.
- The app bar title updates to match the selected tab.

### 3.2 Form validation

Multiple screens have forms with validation logic that should be tested:

**AddEntryDialog (`add_entry_dialog.dart`):**
- Submitting without selecting a project shows validation error.
- Submitting without selecting a category shows validation error.
- Submitting without a description shows validation error.
- Manual mode: start time after end time shows error snackbar.
- Timer mode vs manual mode toggle works.

**ClientEditScreen, ProjectEditScreen, ExpenseEditScreen, TodoEditScreen:**
- Required fields trigger validation errors when empty.
- Valid data submits successfully.

**InvoiceEditScreen:**
- Submitting without selecting a client shows error snackbar.
- Line items total is calculated correctly and displayed.

### 3.3 List screens — empty and populated states

Each list screen (Clients, Projects, Expenses, Invoices, Todos, TimeTracker)
has at least two states that should be tested:

**What to test:**
- Empty state: shows the "No X found" placeholder message.
- Populated state: renders the correct number of items.
- Loading state: shows `CircularProgressIndicator`.

### 3.4 `ActiveTimerCard` widget

**What to test:**
- Renders the description and category of the active entry.
- The elapsed time display updates (verify timer tick).
- Tapping the stop button sets `endTime` on the entry.

### 3.5 Swipe-to-delete (Dismissible)

Multiple screens use `Dismissible` for deletion.

**What to test:**
- Swiping a time entry triggers deletion.
- Swiping a client shows a confirmation dialog (ClientsScreen).
- Swiping an expense triggers deletion.

---

## Priority 4 — Integration / Workflow Tests

These are end-to-end tests that verify complete user workflows.

### 4.1 Time tracking lifecycle

**Workflow:** Start timer → verify active timer card appears → stop timer →
verify entry appears in recent entries list with correct duration.

### 4.2 Invoice creation from time entries

**Workflow:** Create client → create project → add time entries → create invoice
→ fetch time entries → verify line items are populated → verify time entries
are marked as billed.

### 4.3 Expense to invoice flow

**Workflow:** Create expense associated with a client → create invoice → fetch
expenses → verify expense appears as a line item → verify expense is marked as
billed.

### 4.4 Todo to timer flow

**Workflow:** Create a todo → tap "Start Timer" on the todo → verify a time
entry is created and the active timer card appears.

---

## Recommended Refactoring to Improve Testability

Several pieces of business logic are currently embedded inside widget `State`
classes as private methods, making them impossible to unit test without widget
testing infrastructure. Extracting these into standalone functions or service
classes would dramatically improve testability:

| Current location | Function | Suggested extraction |
|---|---|---|
| `_TimeTrackerScreenState._formatDuration` | Duration → HH:MM:SS string | `lib/utils/formatters.dart` |
| `_ReportsScreenState._getDateRange` | TimePeriod → DateTimeRange | `lib/utils/date_utils.dart` |
| `_ReportsScreenState._generateChartGroups` | Map → BarChartGroupData list | `lib/utils/chart_helpers.dart` |
| `_ExpenseEditScreenState._calculateMileageTotal` | distance × rate | `lib/utils/expense_utils.dart` |
| `HomeScreen._getPriorityColor` | Priority string → Color | `lib/utils/priority_utils.dart` |
| `_TimeTrackerScreenState._buildWeeklyTotal` (filter logic) | Filter entries to current week | `lib/utils/time_utils.dart` |
| `_InvoiceEditScreenState._fetchTimeEntries` (aggregation logic) | Group time entries into line items per project | `lib/services/invoice_service.dart` |

### Database abstraction

The screens currently access `AppDatabase` directly via `Provider`. Introducing
a thin repository or DAO layer would allow mocking the database in widget tests
without needing a real SQLite instance:

```
lib/
  repositories/
    client_repository.dart
    project_repository.dart
    time_entry_repository.dart
    expense_repository.dart
    invoice_repository.dart
    todo_repository.dart
```

---

## Suggested Test File Structure

```
test/
  models/
    line_item_test.dart
  utils/
    formatters_test.dart          (after extracting _formatDuration)
    date_utils_test.dart          (after extracting _getDateRange)
    expense_utils_test.dart       (after extracting mileage calc)
  database/
    database_test.dart            (CRUD, defaults, constraints)
    migration_test.dart           (schema migrations)
    cascade_delete_test.dart      (foreign key cascades)
    query_test.dart               (complex joins and filters)
  screens/
    main_screen_test.dart         (navigation)
    home_screen_test.dart         (todo list, priority colors)
    time_tracker/
      time_tracker_screen_test.dart
      add_entry_dialog_test.dart
      active_timer_card_test.dart
    clients/
      clients_screen_test.dart
      client_edit_screen_test.dart
    projects/
      projects_screen_test.dart
      project_edit_screen_test.dart
    expenses/
      expenses_screen_test.dart
      expense_edit_screen_test.dart
    invoices/
      invoices_screen_test.dart
      invoice_edit_screen_test.dart
    reports/
      reports_screen_test.dart
    settings/
      settings_screen_test.dart
    todos/
      todo_edit_screen_test.dart
  integration/
    time_tracking_flow_test.dart
    invoice_creation_flow_test.dart
    todo_to_timer_flow_test.dart
```

---

## Summary of Recommended Testing Priorities

| Priority | Category | Effort | Impact | Key risk mitigated |
|---|---|---|---|---|
| **P1** | LineItem model unit tests | Small | High | Invoice data corruption |
| **P1** | Duration/date utility unit tests | Small (after refactor) | High | Incorrect time/earnings reporting |
| **P2** | Database CRUD + cascade tests | Medium | High | Data loss, orphaned records |
| **P2** | Database migration tests | Medium | High | Upgrade failures, data loss |
| **P2** | Complex query tests | Medium | Medium | Incorrect invoice amounts, wrong report data |
| **P3** | Form validation widget tests | Medium | Medium | Users submitting invalid data |
| **P3** | List screen empty/populated states | Small | Low | UI regressions |
| **P3** | Navigation widget tests | Small | Low | Broken navigation |
| **P4** | End-to-end workflow tests | Large | High | Cross-feature regressions |

The single highest-ROI action is to write unit tests for `LineItem` (Priority
1.1) and database CRUD operations (Priority 2.1), as these protect the core
data integrity of the application with relatively little test infrastructure.
