// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:time_tracker/database/database.dart';

/// Enum representing the different types of notifications the app can generate.
enum NotificationType {
  timerStopped,
  deadlineApproaching,
  timeLimitWarning,
  weeklySummary,
  invoiceOverdue,
  taskOverdue,
  milestoneReached,
}

/// Enum representing notification severity levels, used for visual styling.
enum NotificationSeverity {
  info,
  warning,
  success,
  error,
}

/// A comprehensive in-app notification service that manages the lifecycle of
/// notifications within the Time Tracker application.
///
/// This service handles:
/// - Creating notifications for various app events (timer stops, deadlines, etc.)
/// - Periodic background checks for upcoming deadlines and overdue items
/// - Maintaining read/dismissed state for each notification
/// - Generating weekly summary reports of tracked time
/// - Monitoring project time limits and alerting when thresholds are crossed
/// - Providing a stream of unread notification counts for badge display
class NotificationService extends ChangeNotifier {
  final AppDatabase _db;
  Timer? _periodicCheckTimer;
  Timer? _deadlineCheckTimer;
  Timer? _invoiceCheckTimer;
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  NotificationService(this._db) {
    _initializeService();
  }

  /// Initializes the notification service by loading the initial unread count,
  /// ensuring default preferences exist, and starting all periodic background
  /// check timers for deadlines, invoices, and time limit monitoring.
  Future<void> _initializeService() async {
    await _loadUnreadCount();
    await _ensureDefaultPreferences();
    _startPeriodicChecks();
  }

  /// Loads the current count of unread, non-dismissed notifications from the
  /// database and updates the badge count, notifying all listeners of the change.
  Future<void> _loadUnreadCount() async {
    final count = await (_db.selectOnly(_db.appNotifications)
          ..where(_db.appNotifications.isRead.equals(false) &
              _db.appNotifications.isDismissed.equals(false))
          ..addColumns([_db.appNotifications.id.count()]))
        .map((row) => row.read(_db.appNotifications.id.count()))
        .getSingle();
    _unreadCount = count ?? 0;
    notifyListeners();
  }

  /// Ensures that a default row of notification preferences exists in the
  /// database. If no preferences record is found, it creates one with all
  /// notification types enabled and sensible default thresholds.
  Future<void> _ensureDefaultPreferences() async {
    final existing = await (_db.select(_db.notificationPreferences)
          ..where((p) => p.id.equals(1)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.notificationPreferences).insert(
            NotificationPreferencesCompanion.insert(
              timerStopNotifications: const drift.Value(true),
              deadlineReminders: const drift.Value(true),
              timeLimitWarnings: const drift.Value(true),
              weeklySummary: const drift.Value(true),
              invoiceOverdueAlerts: const drift.Value(true),
              taskOverdueAlerts: const drift.Value(true),
              milestoneNotifications: const drift.Value(true),
              deadlineReminderMinutes: const drift.Value(60),
              timeLimitWarningPercent: const drift.Value(80),
              soundEnabled: const drift.Value(true),
              vibrationEnabled: const drift.Value(true),
            ),
          );
    }
  }

  /// Retrieves the current notification preferences from the database.
  /// Returns null if no preferences record exists (though one should always
  /// be created by [_ensureDefaultPreferences] during initialization).
  Future<NotificationPreference?> getPreferences() async {
    return await (_db.select(_db.notificationPreferences)
          ..where((p) => p.id.equals(1)))
        .getSingleOrNull();
  }

  /// Updates the notification preferences in the database by performing an
  /// upsert (insert-or-update) operation with the provided companion values.
  Future<void> updatePreferences(
      NotificationPreferencesCompanion companion) async {
    await _db
        .into(_db.notificationPreferences)
        .insertOnConflictUpdate(companion);
    notifyListeners();
  }

  /// Starts all periodic background timers:
  /// - Every 5 minutes: checks for approaching task deadlines
  /// - Every 15 minutes: checks for overdue invoices
  /// - Every 30 minutes: checks for project time limit thresholds
  void _startPeriodicChecks() {
    _deadlineCheckTimer?.cancel();
    _deadlineCheckTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => checkDeadlines());

    _invoiceCheckTimer?.cancel();
    _invoiceCheckTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => checkOverdueInvoices());

    _periodicCheckTimer?.cancel();
    _periodicCheckTimer =
        Timer.periodic(const Duration(minutes: 30), (_) => checkTimeLimits());
  }

  // ---------------------------------------------------------------------------
  // Core notification creation
  // ---------------------------------------------------------------------------

  /// Creates a new notification record in the database with the given parameters.
  ///
  /// After inserting, it refreshes the unread count and notifies all listeners
  /// so that badge counts and notification lists update in real-time.
  ///
  /// Parameters:
  /// - [title]: The notification headline shown in the notification center
  /// - [body]: The detailed message body
  /// - [type]: The category of notification (maps to [NotificationType])
  /// - [severity]: Visual severity level (maps to [NotificationSeverity])
  /// - [relatedEntityId]: Optional ID of the related database entity
  /// - [relatedEntityType]: Optional type string (e.g., 'time_entry', 'project')
  /// - [actionRoute]: Optional navigation route for deep-linking
  /// - [metadata]: Optional JSON-encoded string for additional data
  Future<int> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    NotificationSeverity severity = NotificationSeverity.info,
    int? relatedEntityId,
    String? relatedEntityType,
    String? actionRoute,
    String? metadata,
  }) async {
    final id = await _db.into(_db.appNotifications).insert(
          AppNotificationsCompanion.insert(
            title: title,
            body: body,
            type: type.name,
            severity: drift.Value(severity.name),
            createdAt: DateTime.now(),
            relatedEntityId: drift.Value(relatedEntityId),
            relatedEntityType: drift.Value(relatedEntityType),
            actionRoute: drift.Value(actionRoute),
            metadata: drift.Value(metadata),
          ),
        );
    await _loadUnreadCount();
    return id;
  }

  // ---------------------------------------------------------------------------
  // Timer-related notifications
  // ---------------------------------------------------------------------------

  /// Called when a user stops an active timer. Creates a "timer stopped"
  /// notification that includes the task description and the total elapsed
  /// duration formatted as HH:MM:SS.
  ///
  /// Respects the user's [timerStopNotifications] preference setting.
  Future<void> notifyTimerStopped({
    required int timeEntryId,
    required String description,
    required Duration elapsed,
    required String projectName,
  }) async {
    final prefs = await getPreferences();
    if (prefs != null && !prefs.timerStopNotifications) return;

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final durationStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    await createNotification(
      title: 'Timer Stopped',
      body:
          'Completed "$description" on $projectName.\nTotal time: $durationStr',
      type: NotificationType.timerStopped,
      severity: NotificationSeverity.success,
      relatedEntityId: timeEntryId,
      relatedEntityType: 'time_entry',
      actionRoute: '/time_tracker',
      metadata: jsonEncode({
        'duration_seconds': elapsed.inSeconds,
        'project_name': projectName,
        'description': description,
      }),
    );
  }

  /// Called when a user reaches a specific milestone of tracked hours on a
  /// project. Creates an encouraging notification celebrating the achievement.
  ///
  /// Respects the user's [milestoneNotifications] preference setting.
  ///
  /// Milestones are defined in [checkTimeLimits] and include thresholds like
  /// 10, 25, 50, 100, 250, 500, and 1000 hours.
  Future<void> notifyMilestoneReached({
    required String projectName,
    required int totalHours,
    required int projectId,
  }) async {
    final prefs = await getPreferences();
    if (prefs != null && !prefs.milestoneNotifications) return;

    await createNotification(
      title: 'Milestone Reached!',
      body:
          'You\'ve tracked $totalHours hours on "$projectName". Great work keeping up the momentum!',
      type: NotificationType.milestoneReached,
      severity: NotificationSeverity.success,
      relatedEntityId: projectId,
      relatedEntityType: 'project',
      actionRoute: '/reports',
      metadata: jsonEncode({
        'total_hours': totalHours,
        'project_name': projectName,
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Deadline & overdue checks
  // ---------------------------------------------------------------------------

  /// Scans all incomplete todos for approaching deadlines. If a task's deadline
  /// falls within the configured reminder window (default: 60 minutes), and no
  /// duplicate notification already exists for that task, a warning notification
  /// is created.
  ///
  /// Also detects tasks whose deadlines have already passed and creates overdue
  /// notifications for those, provided no duplicate already exists.
  ///
  /// This method runs every 5 minutes via the periodic timer and can also be
  /// called manually.
  Future<void> checkDeadlines() async {
    final prefs = await getPreferences();
    if (prefs == null) return;

    final now = DateTime.now();
    final reminderWindow =
        now.add(Duration(minutes: prefs.deadlineReminderMinutes));

    // Check for approaching deadlines
    if (prefs.deadlineReminders) {
      final upcomingTodos = await (_db.select(_db.todos)
            ..where((t) =>
                t.isCompleted.equals(false) &
                t.deadline.isBiggerThanValue(now) &
                t.deadline.isSmallerOrEqualValue(reminderWindow)))
          .get();

      for (final todo in upcomingTodos) {
        final alreadyNotified = await _hasRecentNotification(
          type: NotificationType.deadlineApproaching,
          relatedEntityId: todo.id,
          withinMinutes: prefs.deadlineReminderMinutes,
        );

        if (!alreadyNotified) {
          final minutesLeft = todo.deadline.difference(now).inMinutes;
          await createNotification(
            title: 'Deadline Approaching',
            body:
                '"${todo.title}" is due in $minutesLeft minutes. Prioritize this task to stay on track.',
            type: NotificationType.deadlineApproaching,
            severity: NotificationSeverity.warning,
            relatedEntityId: todo.id,
            relatedEntityType: 'todo',
            actionRoute: '/todos',
            metadata: jsonEncode({
              'deadline': todo.deadline.toIso8601String(),
              'minutes_remaining': minutesLeft,
              'task_title': todo.title,
            }),
          );
        }
      }
    }

    // Check for overdue tasks
    if (prefs.taskOverdueAlerts) {
      final overdueTodos = await (_db.select(_db.todos)
            ..where((t) =>
                t.isCompleted.equals(false) &
                t.deadline.isSmallerThanValue(now)))
          .get();

      for (final todo in overdueTodos) {
        final alreadyNotified = await _hasRecentNotification(
          type: NotificationType.taskOverdue,
          relatedEntityId: todo.id,
          withinMinutes: 1440, // Only re-notify once per day
        );

        if (!alreadyNotified) {
          final hoursOverdue = now.difference(todo.deadline).inHours;
          await createNotification(
            title: 'Task Overdue',
            body:
                '"${todo.title}" is overdue by $hoursOverdue hours. Consider rescheduling or completing it as soon as possible.',
            type: NotificationType.taskOverdue,
            severity: NotificationSeverity.error,
            relatedEntityId: todo.id,
            relatedEntityType: 'todo',
            actionRoute: '/todos',
            metadata: jsonEncode({
              'deadline': todo.deadline.toIso8601String(),
              'hours_overdue': hoursOverdue,
              'task_title': todo.title,
            }),
          );
        }
      }
    }
  }

  /// Scans all invoices for overdue payment status. An invoice is considered
  /// overdue if its due date has passed and its status is not 'Paid'.
  ///
  /// Creates an error-severity notification for each overdue invoice, with
  /// duplicate suppression of one notification per invoice per day.
  ///
  /// This method runs every 15 minutes via the periodic timer.
  Future<void> checkOverdueInvoices() async {
    final prefs = await getPreferences();
    if (prefs == null || !prefs.invoiceOverdueAlerts) return;

    final now = DateTime.now();

    final overdueInvoices = await (_db.select(_db.invoices)
          ..where((i) => i.dueDate.isSmallerThanValue(now))
          ..where((i) => i.status.isNotIn(['Paid'])))
        .get();

    for (final invoice in overdueInvoices) {
      final alreadyNotified = await _hasRecentNotification(
        type: NotificationType.invoiceOverdue,
        relatedEntityId: invoice.id,
        withinMinutes: 1440,
      );

      if (!alreadyNotified) {
        final daysOverdue = now.difference(invoice.dueDate).inDays;

        // Look up the client name for a more informative notification
        final client = await (_db.select(_db.clients)
              ..where((c) => c.id.equals(invoice.clientId)))
            .getSingleOrNull();

        final clientName = client?.name ?? 'Unknown Client';

        await createNotification(
          title: 'Invoice Overdue',
          body:
              'Invoice ${invoice.invoiceIdString} for $clientName is overdue by $daysOverdue days. Amount: \$${invoice.totalAmount.toStringAsFixed(2)}',
          type: NotificationType.invoiceOverdue,
          severity: NotificationSeverity.error,
          relatedEntityId: invoice.id,
          relatedEntityType: 'invoice',
          actionRoute: '/invoices',
          metadata: jsonEncode({
            'invoice_id': invoice.invoiceIdString,
            'client_name': clientName,
            'amount': invoice.totalAmount,
            'days_overdue': daysOverdue,
          }),
        );
      }
    }
  }

  /// Checks all active projects against their configured monthly time limits.
  ///
  /// For each project that has a monthly time limit set, it calculates the
  /// total hours tracked in the current month and compares against the
  /// configured warning threshold percentage (default: 80%).
  ///
  /// If the tracked hours exceed the threshold, a warning notification is
  /// created. If the tracked hours exceed 100% of the limit, an error-severity
  /// notification is created instead.
  ///
  /// Also checks for hour milestones (10, 25, 50, 100, 250, 500, 1000 hours)
  /// across the entire project lifetime and creates celebratory notifications.
  ///
  /// This method runs every 30 minutes via the periodic timer.
  Future<void> checkTimeLimits() async {
    final prefs = await getPreferences();
    if (prefs == null || !prefs.timeLimitWarnings) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final projects = await (_db.select(_db.projects)
          ..where((p) => p.monthlyTimeLimit.isNotNull()))
        .get();

    for (final project in projects) {
      if (project.monthlyTimeLimit == null) continue;

      final entries = await (_db.select(_db.timeEntries)
            ..where((t) =>
                t.projectId.equals(project.id) &
                t.startTime.isBiggerOrEqualValue(startOfMonth) &
                t.startTime.isSmallerOrEqualValue(endOfMonth) &
                t.endTime.isNotNull()))
          .get();

      double totalHours = 0;
      for (final entry in entries) {
        if (entry.endTime != null) {
          totalHours +=
              entry.endTime!.difference(entry.startTime).inMinutes / 60.0;
        }
      }

      final limitHours = project.monthlyTimeLimit!;
      final percentUsed = (totalHours / limitHours * 100).round();
      final warningThreshold = prefs.timeLimitWarningPercent;

      if (percentUsed >= warningThreshold) {
        final alreadyNotified = await _hasRecentNotification(
          type: NotificationType.timeLimitWarning,
          relatedEntityId: project.id,
          withinMinutes: 480, // Re-notify every 8 hours
        );

        if (!alreadyNotified) {
          final isOverLimit = percentUsed >= 100;
          await createNotification(
            title: isOverLimit
                ? 'Time Limit Exceeded!'
                : 'Time Limit Warning',
            body: isOverLimit
                ? 'Project "${project.name}" has used ${totalHours.toStringAsFixed(1)}h of ${limitHours}h monthly limit ($percentUsed%). Consider pausing work or adjusting the limit.'
                : 'Project "${project.name}" has used ${totalHours.toStringAsFixed(1)}h of ${limitHours}h monthly limit ($percentUsed%). Approaching the configured threshold.',
            type: NotificationType.timeLimitWarning,
            severity:
                isOverLimit ? NotificationSeverity.error : NotificationSeverity.warning,
            relatedEntityId: project.id,
            relatedEntityType: 'project',
            actionRoute: '/projects',
            metadata: jsonEncode({
              'project_name': project.name,
              'total_hours': totalHours,
              'limit_hours': limitHours,
              'percent_used': percentUsed,
            }),
          );
        }
      }
    }

    // Milestone checks across all projects
    if (prefs.milestoneNotifications) {
      await _checkHourMilestones();
    }
  }

  /// Internal helper that checks for significant hour milestones across all
  /// projects. For each project, it calculates the total hours ever tracked
  /// and checks against a predefined list of milestone thresholds.
  ///
  /// Milestones: 10, 25, 50, 100, 250, 500, 1000 hours.
  ///
  /// Only creates one notification per milestone per project (no duplicates).
  Future<void> _checkHourMilestones() async {
    final milestones = [10, 25, 50, 100, 250, 500, 1000];

    final projects = await _db.select(_db.projects).get();

    for (final project in projects) {
      final entries = await (_db.select(_db.timeEntries)
            ..where(
                (t) => t.projectId.equals(project.id) & t.endTime.isNotNull()))
          .get();

      double totalHours = 0;
      for (final entry in entries) {
        if (entry.endTime != null) {
          totalHours +=
              entry.endTime!.difference(entry.startTime).inMinutes / 60.0;
        }
      }

      final totalHoursInt = totalHours.floor();

      for (final milestone in milestones) {
        if (totalHoursInt >= milestone) {
          final alreadyNotified = await _hasExactMilestoneNotification(
            projectId: project.id,
            milestone: milestone,
          );

          if (!alreadyNotified) {
            await notifyMilestoneReached(
              projectName: project.name,
              totalHours: milestone,
              projectId: project.id,
            );
          }
        }
      }
    }
  }

  /// Checks if a milestone notification for a specific project and hour
  /// threshold has ever been created, to prevent duplicate milestone alerts.
  Future<bool> _hasExactMilestoneNotification({
    required int projectId,
    required int milestone,
  }) async {
    final existing = await (_db.select(_db.appNotifications)
          ..where((n) =>
              n.type.equals(NotificationType.milestoneReached.name) &
              n.relatedEntityId.equals(projectId))
          ..limit(100))
        .get();

    for (final notification in existing) {
      if (notification.metadata != null) {
        final meta = jsonDecode(notification.metadata!);
        if (meta['total_hours'] == milestone) {
          return true;
        }
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Weekly summary generation
  // ---------------------------------------------------------------------------

  /// Generates a comprehensive weekly summary notification that includes:
  /// - Total hours tracked during the past 7 days
  /// - Total earnings calculated from project hourly rates
  /// - Number of completed tasks
  /// - Number of time entries logged
  ///
  /// This provides users with a quick overview of their productivity without
  /// needing to navigate to the Reports screen.
  ///
  /// Respects the user's [weeklySummary] preference setting.
  Future<void> generateWeeklySummary() async {
    final prefs = await getPreferences();
    if (prefs == null || !prefs.weeklySummary) return;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Calculate total hours this week
    final timeQuery = _db.select(_db.timeEntries).join([
      drift.innerJoin(
          _db.projects, _db.projects.id.equalsExp(_db.timeEntries.projectId)),
    ])
      ..where(_db.timeEntries.startTime.isBiggerOrEqualValue(weekAgo))
      ..where(_db.timeEntries.endTime.isNotNull());

    final timeResults = await timeQuery.get();

    double totalHours = 0;
    double totalEarnings = 0;
    int entryCount = timeResults.length;

    for (final row in timeResults) {
      final entry = row.readTable(_db.timeEntries);
      final project = row.readTable(_db.projects);
      if (entry.endTime != null) {
        final hours =
            entry.endTime!.difference(entry.startTime).inMinutes / 60.0;
        totalHours += hours;
        if (entry.isBillable) {
          totalEarnings += hours * project.hourlyRate;
        }
      }
    }

    // Count completed tasks this week
    final completedTasks = await (_db.select(_db.todos)
          ..where((t) => t.isCompleted.equals(true)))
        .get();
    final completedThisWeek = completedTasks.length;

    // Count new expenses this week
    final expenses = await (_db.select(_db.expenses)
          ..where((e) => e.date.isBiggerOrEqualValue(weekAgo)))
        .get();
    double totalExpenses = 0;
    for (final expense in expenses) {
      totalExpenses += expense.amount;
    }

    final summaryBody = StringBuffer()
      ..writeln(
          'Hours tracked: ${totalHours.toStringAsFixed(1)}h across $entryCount entries')
      ..writeln(
          'Billable earnings: \$${totalEarnings.toStringAsFixed(2)}')
      ..writeln('Tasks completed: $completedThisWeek')
      ..writeln(
          'Expenses logged: \$${totalExpenses.toStringAsFixed(2)} across ${expenses.length} items');

    if (totalHours > 40) {
      summaryBody.writeln(
          '\nYou logged over 40 hours this week. Remember to take breaks and recharge!');
    } else if (totalHours < 10) {
      summaryBody.writeln(
          '\nLight week with under 10 hours tracked. Consider catching up or reviewing your task list.');
    }

    await createNotification(
      title: 'Weekly Summary',
      body: summaryBody.toString().trim(),
      type: NotificationType.weeklySummary,
      severity: NotificationSeverity.info,
      actionRoute: '/reports',
      metadata: jsonEncode({
        'total_hours': totalHours,
        'total_earnings': totalEarnings,
        'entry_count': entryCount,
        'completed_tasks': completedThisWeek,
        'total_expenses': totalExpenses,
        'expense_count': expenses.length,
        'week_start': weekAgo.toIso8601String(),
        'week_end': now.toIso8601String(),
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification state management
  // ---------------------------------------------------------------------------

  /// Returns a live stream of all non-dismissed notifications, ordered by
  /// creation date (newest first). This stream automatically updates whenever
  /// the underlying database table changes.
  Stream<List<AppNotification>> watchAllNotifications() {
    return (_db.select(_db.appNotifications)
          ..where((n) => n.isDismissed.equals(false))
          ..orderBy([
            (n) => drift.OrderingTerm.desc(n.createdAt),
          ]))
        .watch();
  }

  /// Returns a live stream of only unread, non-dismissed notifications,
  /// ordered by creation date (newest first). Useful for showing a filtered
  /// view in the notification center.
  Stream<List<AppNotification>> watchUnreadNotifications() {
    return (_db.select(_db.appNotifications)
          ..where(
              (n) => n.isRead.equals(false) & n.isDismissed.equals(false))
          ..orderBy([
            (n) => drift.OrderingTerm.desc(n.createdAt),
          ]))
        .watch();
  }

  /// Returns a live stream of the count of unread, non-dismissed notifications.
  /// Used by the notification badge widget to display the current count.
  Stream<int> watchUnreadCount() {
    return (_db.selectOnly(_db.appNotifications)
          ..where(_db.appNotifications.isRead.equals(false) &
              _db.appNotifications.isDismissed.equals(false))
          ..addColumns([_db.appNotifications.id.count()]))
        .map((row) => row.read(_db.appNotifications.id.count()) ?? 0)
        .watchSingle();
  }

  /// Marks a single notification as read by its ID. After updating, it
  /// refreshes the unread count and notifies listeners.
  Future<void> markAsRead(int notificationId) async {
    await (_db.update(_db.appNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .write(const AppNotificationsCompanion(
      isRead: drift.Value(true),
    ));
    await _loadUnreadCount();
  }

  /// Marks all non-dismissed notifications as read. Useful for a "mark all
  /// as read" action in the notification center. Refreshes the count afterward.
  Future<void> markAllAsRead() async {
    await (_db.update(_db.appNotifications)
          ..where((n) => n.isDismissed.equals(false)))
        .write(const AppNotificationsCompanion(
      isRead: drift.Value(true),
    ));
    await _loadUnreadCount();
  }

  /// Dismisses a single notification by its ID, effectively hiding it from
  /// all notification lists. Dismissed notifications are soft-deleted and
  /// remain in the database but are filtered from all queries.
  Future<void> dismissNotification(int notificationId) async {
    await (_db.update(_db.appNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .write(const AppNotificationsCompanion(
      isDismissed: drift.Value(true),
    ));
    await _loadUnreadCount();
  }

  /// Dismisses all notifications at once. Useful for a "clear all" action.
  Future<void> dismissAllNotifications() async {
    await _db.update(_db.appNotifications).write(
          const AppNotificationsCompanion(
        isDismissed: drift.Value(true),
      ),
    );
    await _loadUnreadCount();
  }

  /// Permanently deletes all dismissed notifications from the database.
  /// This is a cleanup operation that reclaims storage space.
  Future<void> deleteAllDismissed() async {
    await (_db.delete(_db.appNotifications)
          ..where((n) => n.isDismissed.equals(true)))
        .go();
  }

  /// Retrieves notifications filtered by type, with an optional limit.
  /// Results are ordered by creation date (newest first).
  Future<List<AppNotification>> getNotificationsByType(
    NotificationType type, {
    int limit = 50,
  }) async {
    return await (_db.select(_db.appNotifications)
          ..where((n) =>
              n.type.equals(type.name) & n.isDismissed.equals(false))
          ..orderBy([(n) => drift.OrderingTerm.desc(n.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Returns aggregated statistics about notifications grouped by type.
  /// Useful for the notification center header or settings screen to show
  /// how many notifications of each type have been generated.
  Future<Map<String, int>> getNotificationStats() async {
    final allNotifications = await (_db.select(_db.appNotifications)
          ..where((n) => n.isDismissed.equals(false)))
        .get();

    final stats = <String, int>{};
    for (final notification in allNotifications) {
      stats.update(notification.type, (count) => count + 1,
          ifAbsent: () => 1);
    }
    return stats;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Checks whether a notification of the given type and related entity has
  /// already been created within the specified time window. This prevents
  /// duplicate notifications from being generated by periodic checks.
  Future<bool> _hasRecentNotification({
    required NotificationType type,
    required int relatedEntityId,
    required int withinMinutes,
  }) async {
    final cutoff =
        DateTime.now().subtract(Duration(minutes: withinMinutes));
    final existing = await (_db.select(_db.appNotifications)
          ..where((n) =>
              n.type.equals(type.name) &
              n.relatedEntityId.equals(relatedEntityId) &
              n.createdAt.isBiggerOrEqualValue(cutoff)))
        .get();
    return existing.isNotEmpty;
  }

  /// Maps a [NotificationType] to a corresponding Material icon for use in
  /// the notification center list and detail views.
  static IconData getIconForType(String type) {
    switch (type) {
      case 'timerStopped':
        return Icons.timer_off;
      case 'deadlineApproaching':
        return Icons.warning_amber_rounded;
      case 'timeLimitWarning':
        return Icons.hourglass_bottom;
      case 'weeklySummary':
        return Icons.summarize;
      case 'invoiceOverdue':
        return Icons.receipt_long;
      case 'taskOverdue':
        return Icons.assignment_late;
      case 'milestoneReached':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  /// Maps a [NotificationSeverity] string to a corresponding color for use
  /// in notification badges, icons, and card decorations.
  static Color getColorForSeverity(String severity) {
    switch (severity) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  /// Returns a human-readable label for a notification type string, used
  /// in filter chips and detail views.
  static String getLabelForType(String type) {
    switch (type) {
      case 'timerStopped':
        return 'Timer Stopped';
      case 'deadlineApproaching':
        return 'Deadline Approaching';
      case 'timeLimitWarning':
        return 'Time Limit Warning';
      case 'weeklySummary':
        return 'Weekly Summary';
      case 'invoiceOverdue':
        return 'Invoice Overdue';
      case 'taskOverdue':
        return 'Task Overdue';
      case 'milestoneReached':
        return 'Milestone Reached';
      default:
        return 'Notification';
    }
  }

  /// Cancels all periodic timers and cleans up resources when the service
  /// is disposed. This is called when the root Provider is disposed.
  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    _deadlineCheckTimer?.cancel();
    _invoiceCheckTimer?.cancel();
    super.dispose();
  }
}
