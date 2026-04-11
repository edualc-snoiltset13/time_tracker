// lib/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/services/notification_service.dart';
import 'package:time_tracker/screens/notifications/notification_center_screen.dart';

/// A reusable notification bell icon widget that displays an animated badge
/// showing the count of unread notifications.
///
/// This widget listens to the [NotificationService] for real-time updates
/// to the unread count and automatically animates the badge in/out when
/// the count changes.
///
/// Features:
/// - Animated scale transition when badge count changes
/// - Red badge with white count text
/// - Displays "9+" for counts greater than 9
/// - Tapping navigates to the [NotificationCenterScreen]
/// - Badge only visible when there are unread notifications
class NotificationBadge extends StatefulWidget {
  /// Optional color override for the bell icon. Defaults to the current
  /// theme's icon color.
  final Color? iconColor;

  /// Optional size override for the bell icon. Defaults to 24.
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _badgeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _badgeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NotificationService>(context);

    return StreamBuilder<int>(
      stream: service.watchUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        // Trigger badge animation when count goes from 0 to positive
        if (count > 0 && !_badgeAnimationController.isCompleted) {
          _badgeAnimationController.forward();
        } else if (count == 0) {
          _badgeAnimationController.reset();
        }

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                count > 0
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: widget.iconColor,
                size: widget.iconSize,
              ),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: ScaleTransition(
                    scale: _badgeScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(100),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: count > 0
              ? '$count unread notification${count == 1 ? '' : 's'}'
              : 'Notifications',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const NotificationCenterScreen(),
            ));
          },
        );
      },
    );
  }
}

/// A smaller, inline version of the notification badge that can be used
/// within list tiles, cards, or other compact layouts.
///
/// Unlike [NotificationBadge], this widget does not include an icon button
/// wrapper and is purely a visual count indicator.
class NotificationCountChip extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationCountChip({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
