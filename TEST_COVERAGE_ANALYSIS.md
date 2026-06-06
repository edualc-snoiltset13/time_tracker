# Test Coverage Analysis & Improvement Proposal — time_tracker

> Status: **analysis & proposal only**. This document does not add tests or test
> tooling; it inventories the current state and recommends a prioritized path to
> meaningful coverage.

## 1. Summary

| Metric | Value |
|---|---|
| Source size | ~20,000 lines (`lib/`) |
| Relevant test files | **0** (only the dead Flutter counter boilerplate) |
| Test framework | `flutter_test` only |
| Mocking / integration deps | none (`mockito`/`mocktail`, `integration_test` absent) |
| CI running tests | none |
| Estimated coverage | **~0%** |

`time_tracker` is a cross-platform Flutter time-tracking & invoicing app:
Drift/SQLite persistence, Provider state, 13 screens, PDF invoice generation,
and a reports/analytics dashboard. Despite ~20k lines and revenue-/data-critical
logic, the only test is `test/widget_test.dart` — the auto-generated counter
boilerplate that references a feature the app does not have. It is effectively
dead and should be replaced.

The biggest risks are silent regressions in **money math** (invoice totals),
**data integrity** (DB cascade deletes / migrations), and **date-range
calculations** (reports) — none of which are currently guarded by tests.

## 2. Inventory: source vs. tests

| Area | Representative files | Existing tests | Coverage |
|---|---|---|---|
| Data model | `lib/models/line_item.dart` | none | 0% |
| Services | `lib/services/idle_service.dart` | none | 0% |
| Database / ORM | `lib/database/database.dart` (7 tables, v3 migrations) | none | 0% |
| PDF / invoicing | `lib/utils/pdf_generator.dart` | none | 0% |
| Reports / analytics | `lib/screens/reports/reports_screen.dart` | none | 0% |
| Screens (×13) | `invoice_edit_screen.dart` (~506 LOC), `time_tracker_screen.dart`, edit/list screens | none | 0% |
| App wiring | `lib/main.dart` (Provider setup) | none | 0% |
| (boilerplate) | `test/widget_test.dart` | dead/auto-generated | n/a |

`dev_dependencies` currently: `flutter_test`, `drift_dev`, `build_runner`,
`flutter_lints`. No mocking, no integration-test, no coverage/CI.

## 3. Prioritized roadmap

### P1 — Pure-logic unit tests (highest ROI, no infra changes)
These need only `flutter_test` and run fast/deterministically.

- **`line_item.dart`**: `total` getter (`quantity * unitPrice`, incl. zero &
  fractional hours); `toJson`/`fromJson` round-trip; `lineItemsToJson` /
  `lineItemsFromJson` for empty and multi-item lists; behavior on malformed
  JSON (missing/extra fields, `int` vs `double`).
- **`idle_service.dart`**: `isIdle` exactly at / just below / above the
  threshold; `recordActivity` resets `lastActivity`. Time-dependent logic
  should use an injectable clock or `package:fake_async` for determinism.
- **Replace** the dead `test/widget_test.dart` boilerplate.

### P2 — Database tests (data integrity)
Use Drift's `NativeDatabase.memory()` for fast, isolated DB tests.

- CRUD for each table; stream watchers emit on change.
- **Cascade deletes**: deleting a Client removes its Projects → TimeEntries.
- **Migrations** v1→v2→v3 (Drift's `SchemaVerifier` / migration harness).

### P3 — Business logic (revenue-critical)
- **Invoice math**: line-item totals and grand totals; invoice-ID generation;
  status transitions (Draft→Sent→Paid). Recommend extracting the calculation
  helpers out of `pdf_generator.dart` / `invoice_edit_screen.dart` so totals can
  be asserted without rendering a PDF.
- **Reports date ranges**: `thisWeek` / `lastWeek` / `lastMonth` / `thisYear`
  boundary correctness (week start, month/year edges, DST/timezone).
- **Duration formatting** in the time tracker.

### P4 — Widget & integration tests (UX / flows)
- Widget tests for the largest/most complex screens first:
  `invoice_edit_screen.dart` (~506 LOC), `time_tracker_screen.dart`, and form
  validation across the edit screens.
- `integration_test` for the core flow: start timer → stop → create invoice →
  generate PDF.

## 4. Recommended tooling (adopt when implementing)

| Concern | Recommendation |
|---|---|
| Mocking | `mocktail` (or `mockito` + `build_runner`) |
| DB tests | Drift `NativeDatabase.memory()`, `SchemaVerifier` for migrations |
| Time/async | `package:fake_async`; injectable clock in `IdleService` |
| E2E | `integration_test` (Flutter SDK) |
| Coverage / CI | `flutter test --coverage` + GitHub Actions workflow, lcov gate |

## 5. Suggested first test cases (seed the suite)

```dart
// test/models/line_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  test('total = quantity * unitPrice', () {
    expect(LineItem(description: 'x', quantity: 2.5, unitPrice: 40).total, 100);
  });

  test('JSON round-trip preserves values', () {
    final items = [LineItem(description: 'Dev', quantity: 3, unitPrice: 50)];
    final decoded = lineItemsFromJson(lineItemsToJson(items));
    expect(decoded.single.total, 150);
    expect(decoded.single.description, 'Dev');
  });
}
```

```dart
// test/services/idle_service_test.dart  (with injectable clock or fake_async)
test('isIdle becomes true once threshold elapses', () {
  // record activity, advance fake time past idleThreshold, expect isIdle == true
});
```

## 6. Out of scope (this task)
Writing the tests above, adding `mocktail`/`integration_test`/coverage deps,
refactoring `pdf_generator` to separate calculation from rendering, and adding
CI. These are recommendations; implementation is deferred.
