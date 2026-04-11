// lib/screens/notifications/notification_center_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/services/notification_service.dart';
import 'package:time_tracker/screens/notifications/notification_detail_screen.dart';

/// The main Notification Center screen that displays all in-app notifications
/// in a scrollable list with filtering, bulk actions, and swipe-to-dismiss.
///
/// Features:
/// - Filter by notification type using horizontally scrollable filter chips
/// - Filter between All / Unread views via toggle buttons
/// - Mark all notifications as read with a single tap
/// - Dismiss all notifications via the app bar menu
/// - Generate on-demand weekly summaries
/// - Swipe individual notifications to dismiss them
/// - Tap notifications to view full details and mark as read
/// - Visual indicators for unread state, severity, and type
/// - Relative timestamps ("2 minutes ago", "3 hours ago", etc.)
/// - Empty state with contextual messaging based on active filters
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedTypeFilter;
  bool _showUnreadOnly = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// The available notification type filters, mapping internal type names to
  /// human-readable labels for the filter chips.
  final List<Map<String, String>> _typeFilters = [
    {'value': 'timerStopped', 'label': 'Timer'},
    {'value': 'deadlineApproaching', 'label': 'Deadlines'},
    {'value': 'timeLimitWarning', 'label': 'Time Limits'},
    {'value': 'weeklySummary', 'label': 'Summaries'},
    {'value': 'invoiceOverdue', 'label': 'Invoices'},
    {'value': 'taskOverdue', 'label': 'Overdue Tasks'},
    {'value': 'milestoneReached', 'label': 'Milestones'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Formats a [DateTime] as a relative time string for display in the
  /// notification list. Shows "Just now" for the last minute, "X minutes ago"
  /// for the last hour, "X hours ago" for today, "Yesterday" for the previous
  /// day, and the full formatted date for anything older.
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }

  /// Builds the horizontally scrollable row of filter chips that allow users
  /// to filter notifications by type. The "All" chip clears the filter.
  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedTypeFilter == null,
              onSelected: (_) {
                setState(() => _selectedTypeFilter = null);
              },
              selectedColor: Colors.deepPurple.withAlpha(100),
              checkmarkColor: Colors.white,
            ),
          ),
          ..._typeFilters.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter['label']!),
                selected: _selectedTypeFilter == filter['value'],
                onSelected: (_) {
                  setState(() {
                    _selectedTypeFilter =
                        _selectedTypeFilter == filter['value']
                            ? null
                            : filter['value'];
                  });
                },
                avatar: Icon(
                  NotificationService.getIconForType(filter['value']!),
                  size: 16,
                ),
                selectedColor: Colors.deepPurple.withAlpha(100),
                checkmarkColor: Colors.white,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds a single notification card in the list. Each card includes:
  /// - A colored leading icon based on notification type and severity
  /// - The notification title and truncated body
  /// - A relative timestamp
  /// - An unread indicator dot
  /// - Swipe-to-dismiss functionality
  /// - Tap to navigate to the detail screen
  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    NotificationService service,
  ) {
    final icon = NotificationService.getIconForType(notification.type);
    final color = NotificationService.getColorForSeverity(notification.severity);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade800,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: 4),
            Text('Dismiss', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      onDismissed: (_) {
        service.dismissNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: isUnread ? 3 : 1,
        color: isUnread
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor.withAlpha(180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isUnread
              ? BorderSide(color: color.withAlpha(100), width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            service.markAsRead(notification.id);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailScreen(notification: notification),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon with severity-colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                // Main content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatRelativeTime(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              NotificationService.getLabelForType(
                                  notification.type),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state widget shown when no notifications match the
  /// current filters. Displays a contextual icon and message based on
  /// whether the user is viewing all notifications or a filtered subset.
  Widget _buildEmptyState() {
    final hasFilters = _selectedTypeFilter != null || _showUnreadOnly;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No notifications match your filters'
                  : 'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing your filters to see all notifications.'
                  : 'Notifications will appear here when timers stop, deadlines approach, and milestones are reached.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTypeFilter = null;
                    _showUnreadOnly = false;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the summary statistics header that shows a compact row of counts
  /// grouped by notification type, providing a quick overview of the
  /// notification distribution.
  Widget _buildStatsHeader(List<AppNotification> notifications) {
    final typeCount = <String, int>{};
    for (final n in notifications) {
      typeCount.update(n.type, (c) => c + 1, ifAbsent: () => 1);
    }

    if (typeCount.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: typeCount.entries.take(4).map((entry) {
          final color =
              NotificationService.getColorForSeverity(_getSeverityForType(entry.key));
          return Column(
            children: [
              Icon(
                NotificationService.getIconForType(entry.key),
                color: color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.value}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _getShortLabel(entry.key),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Maps a notification type to a default severity string for styling the
  /// statistics header icons when actual severity data isn't available.
  String _getSeverityForType(String type) {
    switch (type) {
      case 'timerStopped':
      case 'milestoneReached':
        return 'success';
      case 'deadlineApproaching':
      case 'timeLimitWarning':
        return 'warning';
      case 'invoiceOverdue':
      case 'taskOverdue':
        return 'error';
      default:
        return 'info';
    }
  }

  /// Returns a very short label for a notification type, used in the compact
  /// statistics header where space is limited.
  String _getShortLabel(String type) {
    switch (type) {
      case 'timerStopped':
        return 'Timers';
      case 'deadlineApproaching':
        return 'Due Soon';
      case 'timeLimitWarning':
        return 'Limits';
      case 'weeklySummary':
        return 'Summaries';
      case 'invoiceOverdue':
        return 'Invoices';
      case 'taskOverdue':
        return 'Overdue';
      case 'milestoneReached':
        return 'Goals';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          // Toggle between All and Unread views
          IconButton(
            icon: Icon(
              _showUnreadOnly
                  ? Icons.mark_email_unread
                  : Icons.mark_email_read,
            ),
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
            onPressed: () {
              setState(() => _showUnreadOnly = !_showUnreadOnly);
            },
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              service.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
          // Overflow menu with additional actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'dismiss_all':
                  _showDismissAllDialog(context, service);
                  break;
                case 'generate_summary':
                  service.generateWeeklySummary();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weekly summary generated')),
                  );
                  break;
                case 'check_deadlines':
                  service.checkDeadlines();
                  service.checkOverdueInvoices();
                  service.checkTimeLimits();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Running checks...')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate_summary',
                child: ListTile(
                  leading: Icon(Icons.summarize),
                  title: Text('Generate Weekly Summary'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'check_deadlines',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Check Deadlines Now'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'dismiss_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text('Dismiss All', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterChips(),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _showUnreadOnly
                    ? service.watchUnreadNotifications()
                    : service.watchAllNotifications(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var notifications = snapshot.data!;

                  // Apply type filter
                  if (_selectedTypeFilter != null) {
                    notifications = notifications
                        .where((n) => n.type == _selectedTypeFilter)
                        .toList();
                  }

                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: notifications.length + 1, // +1 for stats header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildStatsHeader(notifications);
                      }
                      return _buildNotificationCard(
                        context,
                        notifications[index - 1],
                        service,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before dismissing all notifications.
  /// This is a destructive action that hides all notifications from the list.
  void _showDismissAllDialog(
      BuildContext context, NotificationService service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dismiss All Notifications'),
          content: const Text(
              'Are you sure you want to dismiss all notifications? They will be hidden from this list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                service.dismissAllNotifications();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notifications dismissed')),
                );
              },
              child: Text(
                'Dismiss All',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
