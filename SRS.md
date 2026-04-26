# Software Requirements Specification (SRS)

## Time Tracker

| Item | Value |
|---|---|
| Document version | 1.0 |
| Date | 2026-04-26 |
| Status | Draft |
| Project | Time Tracker (Flutter) |

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) describes the functional and non-functional requirements of the **Time Tracker** application — a cross-platform desktop and mobile app that allows freelancers, consultants, and small teams to manage clients, projects, tasks, time entries, expenses, and PDF invoices from a single, locally-stored application.

The intended audience is the project's developers, contributors, reviewers, testers, and downstream maintainers.

### 1.2 Scope
Time Tracker is a standalone, single-user application built with Flutter. It targets Android, iOS, Windows, macOS, and Linux from a single codebase. All data is stored locally in a SQLite database via the Drift persistence library; the application does not require an internet connection or a server backend.

The product covers the following capability areas:

- Client and project management with hourly rates and monthly time limits.
- Real-time and manual time tracking with categorization and billable flags.
- A to-do list with priorities, deadlines, project association, and timer integration.
- Expense tracking, including mileage with automatic cost calculation.
- Generation of professional PDF invoices from time entries and expenses.
- Reporting and visual analytics for time and revenue.
- Configurable company information and invoice letterhead.

Out of scope for v1.0:

- Multi-user accounts, authentication, or role-based access.
- Cloud sync, backup, or multi-device data merging.
- Online payment processing.
- Team collaboration or shared projects.

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|---|---|
| SRS | Software Requirements Specification |
| Drift | A reactive Dart/Flutter persistence library on top of SQLite |
| PDF | Portable Document Format |
| Client | A customer entity for whom projects and invoices are tracked |
| Project | A unit of billable work belonging to a single client |
| Time Entry | A recorded interval of work (manual or live-tracked) attached to a project |
| To-do | A task in the user's to-do list, optionally linked to a project |
| Expense | A cost incurred against a project or client (incl. mileage) |
| Invoice | A billing document derived from time entries and/or expenses |
| Letterhead | Company branding (name, address, logo) printed on invoices |

### 1.4 References
- README.md (project overview and feature list)
- `lib/database/database.dart` (data model definitions)
- `lib/main.dart` (application entry point)
- `lib/screens/main_screen.dart` (top-level navigation)
- Flutter SDK documentation — https://flutter.dev/docs
- Drift documentation — https://drift.simonbinder.eu/

### 1.5 Overview
Section 2 provides an overall description of the product, its users, and its operating environment. Section 3 enumerates the specific functional requirements grouped by feature area. Section 4 defines the data model. Section 5 covers external interfaces, and Section 6 lists non-functional requirements. Section 7 captures assumptions and constraints.

---

## 2. Overall Description

### 2.1 Product Perspective
Time Tracker is a self-contained client application. There is no server component. The application bundles its own SQLite database (via `sqlite3_flutter_libs`) and stores it in the platform-specific application support directory (see `_openConnection()` in `lib/database/database.dart`).

State management is handled through the `provider` package. The single `AppDatabase` instance is provided at the root of the widget tree, alongside an `IdleService` that listens to global pointer events to detect user inactivity for timer purposes.

### 2.2 Product Functions
At a high level the application provides the following modules, each accessible from the bottom navigation bar (`lib/screens/main_screen.dart`):

1. **Tasks (Home):** Displays the to-do list and lets the user start a timer from a task.
2. **Tracker:** Live timer plus a list of recent time entries.
3. **Projects:** CRUD over projects, grouped by client.
4. **Clients:** CRUD over clients.
5. **Expenses:** CRUD over expenses, including mileage.
6. **Invoices:** Listing and creation of PDF invoices.
7. **Reports:** Charts and aggregates over time and revenue.
8. **Settings:** Company information and letterhead configuration.

### 2.3 User Classes and Characteristics
There is a single user class:

- **Solo user (freelancer / consultant / small business owner):** Owns the device, has full administrative access to all data. No authentication is required by the app itself.

### 2.4 Operating Environment
- **Target platforms:** Android, iOS, Windows, macOS, Linux.
- **Runtime:** Flutter stable channel; Dart SDK as pinned in `pubspec.yaml`.
- **Storage:** Local SQLite file `app_tracker.sqlite` in the platform application support directory.
- **External tooling:** Native printing/PDF dialog via the `printing` plugin; native file picker via `file_picker` (e.g. for selecting a logo).

### 2.5 Design and Implementation Constraints
- The application must run from a single Flutter codebase across all five target platforms.
- Persistence must use Drift with code generation via `build_runner`.
- The database schema is versioned and must support forward migrations (`schemaVersion` in `AppDatabase`).
- The UI must use Material 3 / `ThemeData.dark()` styling consistent with `lib/main.dart`.
- All data is stored locally; no requirement (or permission) for network access.

### 2.6 Assumptions and Dependencies
- The user has Flutter installed for development; end users receive prebuilt platform binaries.
- The host OS provides write access to the application support directory.
- A printer or PDF viewer is available on the host OS for invoice output.

---

## 3. Functional Requirements

Each requirement is identified as `FR-<area>-<n>`. Priority is **Must**, **Should**, or **May**.

### 3.1 Client Management
- **FR-CLI-1 (Must):** The user shall be able to create a client with a name, optional email, optional address, and a currency (default `USD`).
- **FR-CLI-2 (Must):** The user shall be able to view a list of all clients.
- **FR-CLI-3 (Must):** The user shall be able to edit any field of an existing client.
- **FR-CLI-4 (Must):** The user shall be able to delete a client. Deleting a client shall cascade-delete its projects, time entries, expenses linked to those projects, and invoices.
- **FR-CLI-5 (Should):** The currency selected for a client shall propagate to invoice totals for that client.

### 3.2 Project Management
- **FR-PRJ-1 (Must):** The user shall be able to create a project linked to exactly one client, with a name, hourly rate, optional monthly time limit (in minutes), and a status defaulting to `Active`.
- **FR-PRJ-2 (Must):** Projects shall be displayed grouped by client.
- **FR-PRJ-3 (Must):** The user shall be able to edit and delete projects.
- **FR-PRJ-4 (Should):** When a monthly time limit is set, the UI shall indicate progress toward that limit for the current month.
- **FR-PRJ-5 (Must):** Deleting a project shall cascade-delete its time entries, todos, and expenses linked to that project.

### 3.3 Time Tracking
- **FR-TT-1 (Must):** The user shall be able to start a live timer for a selected project, with a description and a category.
- **FR-TT-2 (Must):** The user shall be able to stop the live timer; on stop, a `TimeEntry` shall be persisted with the captured `startTime` and `endTime`.
- **FR-TT-3 (Must):** The user shall be able to create a manual time entry by specifying project, description, start, end, and category.
- **FR-TT-4 (Must):** The user shall be able to edit and delete existing time entries.
- **FR-TT-5 (Must):** Each time entry shall have a `isBillable` flag (default `true`) and an `isBilled` flag (default `false`).
- **FR-TT-6 (Should):** Each time entry shall have an `isLogged` flag for marking that the entry has been logged in an external platform.
- **FR-TT-7 (Should):** The application shall detect user inactivity through the `IdleService` and surface a prompt or visual indicator to the user when the timer is running but no input has been recorded for a configurable period.
- **FR-TT-8 (Must):** Recent time entries shall be visible from the Time Tracker screen.

### 3.4 To-Do / Task Management
- **FR-TODO-1 (Must):** The user shall be able to create a to-do with a title, optional description, project association, category, deadline, priority, scheduled start time, and optional estimated hours.
- **FR-TODO-2 (Must):** Todos shall display on the Home screen with their completion status.
- **FR-TODO-3 (Must):** The user shall be able to mark a to-do as complete or incomplete.
- **FR-TODO-4 (Should):** The user shall be able to start the live timer for the project of a to-do directly from the Home screen.
- **FR-TODO-5 (Must):** The user shall be able to edit and delete todos.

### 3.5 Expense Tracking
- **FR-EXP-1 (Must):** The user shall be able to create an expense with a description, category, amount, and date.
- **FR-EXP-2 (Must):** An expense may optionally be linked to a project, a client, or both.
- **FR-EXP-3 (Should):** For mileage-style expenses, the user shall enter `distance` and `costPerUnit`; the application shall compute `amount = distance × costPerUnit`.
- **FR-EXP-4 (Must):** Each expense shall have an `isBilled` flag (default `false`).
- **FR-EXP-5 (Must):** The user shall be able to edit and delete expenses.

### 3.6 Invoicing
- **FR-INV-1 (Must):** The user shall be able to create an invoice for a single client, comprising selected unbilled time entries and unbilled expenses for that client.
- **FR-INV-2 (Must):** The application shall persist each invoice with: a user-visible `invoiceIdString`, client reference, issue date, due date, total amount, status, optional notes, and a JSON-encoded list of line items.
- **FR-INV-3 (Must):** The application shall generate a PDF rendering of the invoice using the `pdf` and `printing` packages.
- **FR-INV-4 (Must):** When the company `showLetterhead` setting is enabled, the PDF shall include the configured company name, address, and logo.
- **FR-INV-5 (Must):** Time entries and expenses included in a generated invoice shall be marked `isBilled = true`.
- **FR-INV-6 (Should):** The user shall be able to view, share, save, or print the generated PDF using the platform's native dialog.
- **FR-INV-7 (Must):** The user shall be able to list and re-open existing invoices.

### 3.7 Reporting
- **FR-RPT-1 (Must):** The Reports screen shall display visual summaries (charts) of tracked time and revenue using `fl_chart`.
- **FR-RPT-2 (Should):** The user shall be able to filter the report by date range, client, and project.
- **FR-RPT-3 (Should):** The reports shall surface unbilled time and expenses to assist with invoicing.

### 3.8 Company Settings
- **FR-SET-1 (Must):** The user shall be able to configure a company name, company address, and an optional logo (selected via the native file picker).
- **FR-SET-2 (Must):** The user shall be able to toggle whether the letterhead is rendered on invoices.
- **FR-SET-3 (Must):** Company settings shall be stored as a singleton row in the `CompanySettings` table.

### 3.9 Navigation and Shell
- **FR-NAV-1 (Must):** The application shall present a bottom navigation bar with entries for Tasks, Tracker, Projects, Clients, Expenses, Invoices, Reports, and Settings.
- **FR-NAV-2 (Must):** The selected screen's title shall appear in the application bar.

### 3.10 Database & Migrations
- **FR-DB-1 (Must):** All data shall be persisted in a single local SQLite file managed by Drift.
- **FR-DB-2 (Must):** The schema shall be versioned (`schemaVersion`) and shall provide forward migrations on application upgrade.
- **FR-DB-3 (Must):** Foreign keys shall enforce cascade deletion as defined in the data model (Section 4).

---

## 4. Data Model

The data model below mirrors `lib/database/database.dart`. All primary keys are auto-incrementing integers.

### 4.1 Clients
| Column | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| name | text | required |
| email | text | nullable |
| address | text | nullable |
| currency | text | default `'USD'` |

### 4.2 Projects
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| clientId | int | FK → Clients.id, ON DELETE CASCADE |
| name | text | required |
| hourlyRate | real | required |
| monthlyTimeLimit | int | nullable |
| status | text | default `'Active'` |

### 4.3 TimeEntries
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| projectId | int | FK → Projects.id, ON DELETE CASCADE |
| description | text | required |
| startTime | datetime | required |
| endTime | datetime | nullable (live timer) |
| category | text | required |
| isBillable | bool | default `true` |
| isBilled | bool | default `false` |
| isLogged | bool | default `false` |

### 4.4 Expenses
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| description | text | required |
| projectId | int | FK → Projects.id, nullable, ON DELETE CASCADE |
| clientId | int | FK → Clients.id, nullable, ON DELETE CASCADE |
| category | text | required |
| amount | real | required |
| date | datetime | required |
| distance | real | nullable |
| costPerUnit | real | nullable |
| isBilled | bool | default `false` |

### 4.5 Invoices
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| invoiceIdString | text | required, user-visible identifier |
| clientId | int | FK → Clients.id, ON DELETE CASCADE |
| issueDate | datetime | required |
| dueDate | datetime | required |
| totalAmount | real | required |
| status | text | required |
| notes | text | nullable |
| lineItemsJson | text | nullable |

### 4.6 Todos
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| title | text | required |
| description | text | nullable |
| projectId | int | FK → Projects.id, ON DELETE CASCADE |
| category | text | required |
| deadline | datetime | required |
| priority | text | required |
| isCompleted | bool | default `false` |
| startTime | datetime | required |
| estimatedHours | real | nullable |

### 4.7 CompanySettings (singleton)
| Column | Type | Constraints |
|---|---|---|
| id | int | PK |
| companyName | text | required |
| companyAddress | text | required |
| logoPath | text | nullable |
| showLetterhead | bool | default `true` |

---

## 5. External Interface Requirements

### 5.1 User Interfaces
- The UI uses Flutter Material with a dark theme (`ThemeData.dark()`) seeded with `Colors.deepPurple`. Primary navigation is a fixed bottom navigation bar. Floating action buttons follow the dark accent palette.
- Forms (clients, projects, todos, expenses, invoices) use modal screens or dialogs and apply standard input validation (required fields, numeric ranges).

### 5.2 Hardware Interfaces
- None beyond standard pointer/touch input. The `IdleService` listens to pointer events at the application root to detect inactivity.

### 5.3 Software Interfaces
- **SQLite (via Drift):** Local relational storage.
- **Native file picker (`file_picker`):** For selecting a company logo image.
- **PDF / Printing (`pdf`, `printing`, `open_file`):** For rendering and presenting invoice PDFs through the OS dialogs.
- **Path Provider (`path_provider`):** Resolves the application support directory for the database file.
- **Localization (`intl`):** Date and currency formatting.

### 5.4 Communications Interfaces
- None. The application operates entirely offline.

---

## 6. Non-Functional Requirements

### 6.1 Performance
- **NFR-PERF-1:** Cold start time on a mid-tier device shall not exceed 3 seconds.
- **NFR-PERF-2:** All list views (clients, projects, time entries, todos, expenses, invoices) shall remain responsive (< 100 ms interaction latency) for at least 10,000 records.
- **NFR-PERF-3:** Live timer updates shall not exceed 1 second drift over a continuous 8-hour run.

### 6.2 Reliability
- **NFR-REL-1:** The database shall survive abrupt app termination without corruption (SQLite WAL semantics).
- **NFR-REL-2:** Schema migrations shall complete successfully when upgrading from any previously released schema version to the latest.

### 6.3 Usability
- **NFR-USE-1:** Primary actions on every screen shall be reachable in at most two taps from the bottom navigation bar.
- **NFR-USE-2:** Destructive actions (delete client/project/invoice) shall require explicit confirmation.

### 6.4 Portability
- **NFR-PORT-1:** A single codebase shall produce builds for Android, iOS, Windows, macOS, and Linux without platform-specific feature divergence other than what the OS dictates (e.g. file picker chrome).

### 6.5 Maintainability
- **NFR-MAIN-1:** Code shall conform to the lint rules in `analysis_options.yaml` (`flutter_lints`).
- **NFR-MAIN-2:** All persistence access shall go through the Drift-generated `AppDatabase`; raw SQL outside Drift is disallowed.

### 6.6 Security & Privacy
- **NFR-SEC-1:** No user data shall leave the device. The app shall not request network permissions on platforms where they are declared explicitly.
- **NFR-SEC-2:** The local database shall be stored in the OS-provided application support directory, isolated per user account.

### 6.7 Localization
- **NFR-LOC-1:** Date and currency display shall use the device locale via `intl`. Per-client currency overrides invoice formatting.

---

## 7. Constraints, Assumptions, and Open Questions

### 7.1 Constraints
- The app is single-user; no concurrent multi-device editing is supported.
- All money calculations use double-precision floats (`real`); rounding is applied at presentation time. Currencies with sub-cent precision are not supported.

### 7.2 Assumptions
- The user keeps regular OS-level backups of the application support directory if data preservation across device loss matters.
- The user has authority to issue invoices in the configured currency.

### 7.3 Open Questions / Future Work
- **OQ-1:** Should the application offer an export/import (JSON or SQLite copy) facility for backup and migration?
- **OQ-2:** Should invoices support partial payments and a payment history?
- **OQ-3:** Should `isLogged` integrate with a specific external platform (e.g. Jira, Toggl) or remain a manual flag?
- **OQ-4:** Should monthly time-limit overruns trigger notifications?

---

## 8. Acceptance Criteria

The product shall be considered acceptable for v1.0 release when:

1. All **Must** functional requirements in Section 3 are implemented and pass manual verification on at least Android and one desktop OS.
2. The data model in Section 4 is reflected one-to-one in the Drift schema with current `schemaVersion`, and the migration from prior versions does not lose data.
3. A user can complete the end-to-end flow: create client → create project → track time → record expense → generate PDF invoice → mark entries as billed, without errors.
4. Non-functional requirements NFR-PERF-1, NFR-REL-1, and NFR-SEC-1 are validated.
