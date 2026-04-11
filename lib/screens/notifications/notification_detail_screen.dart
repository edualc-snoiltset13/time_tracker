// lib/screens/notifications/notification_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/services/notification_service.dart';

/// A detail screen that displays the full content and metadata of a single
/// notification. Accessed by tapping a notification card in the
/// [NotificationCenterScreen].
///
/// Features:
/// - Full notification title and body text (no truncation)
/// - Visual severity indicator with colored icon and label
/// - Notification type badge
/// - Exact creation timestamp
/// - Read/unread status indicator
/// - Parsed metadata displayed as key-value pairs (if present)
/// - Related entity information (type and ID)
/// - Action buttons: mark as read/unread, dismiss
/// - Back navigation returns to the notification center
class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  /// Builds a styled metadata section that displays the parsed JSON metadata
  /// as a formatted list of key-value pairs within a rounded container.
  ///
  /// Keys are converted from camelCase/snake_case to Title Case for readability.
  /// Values are formatted based on their type (numbers get decimal formatting,
  /// ISO dates are parsed to readable format, etc.).
  Widget _buildMetadataSection(Map<String, dynamic> metadata) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          ...metadata.entries.map((entry) {
            final formattedKey = _formatMetadataKey(entry.key);
            final formattedValue = _formatMetadataValue(entry.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      formattedKey,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formattedValue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Converts a camelCase or snake_case key string into a human-readable
  /// Title Case label. For example:
  /// - "totalHours" -> "Total Hours"
  /// - "project_name" -> "Project Name"
  /// - "durationSeconds" -> "Duration Seconds"
  String _formatMetadataKey(String key) {
    // Convert camelCase to spaces
    final withSpaces = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    // Convert snake_case to spaces and capitalize each word
    return withSpaces
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  /// Formats a metadata value for display. Handles:
  /// - Numbers: displayed with up to 2 decimal places
  /// - ISO 8601 date strings: parsed and formatted as readable dates
  /// - Other strings: displayed as-is
  String _formatMetadataValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is String) {
      // Try to parse as ISO date
      final date = DateTime.tryParse(value);
      if (date != null) {
        return DateFormat.yMMMd().add_jm().format(date);
      }
      return value;
    }
    return value.toString();
  }

  /// Builds an information row used in the detail cards. Each row contains
  /// a leading icon, a label, and a value, arranged in a consistent layout.
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NotificationService>(context, listen: false);
    final icon = NotificationService.getIconForType(notification.type);
    final color = NotificationService.getColorForSeverity(notification.severity);
    final typeLabel = NotificationService.getLabelForType(notification.type);

    // Parse metadata if available
    Map<String, dynamic>? metadata;
    if (notification.metadata != null) {
      try {
        metadata = jsonDecode(notification.metadata!) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        actions: [
          if (!notification.isRead)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'Mark as read',
              onPressed: () {
                service.markAsRead(notification.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as read')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Dismiss notification',
            onPressed: () {
              service.dismissNotification(notification.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification dismissed')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with icon and title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Colors.grey.withAlpha(30)
                              : Colors.deepPurple.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.isRead ? 'Read' : 'Unread',
                          style: TextStyle(
                            color: notification.isRead
                                ? Colors.grey
                                : Colors.deepPurple.shade300,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Body section with the full notification message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Information card with notification properties
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    'Created',
                    DateFormat.yMMMd().add_jm().format(notification.createdAt),
                    Colors.blue,
                  ),
                  _buildInfoRow(
                    Icons.priority_high,
                    'Severity',
                    notification.severity[0].toUpperCase() +
                        notification.severity.substring(1),
                    color,
                  ),
                  if (notification.relatedEntityType != null)
                    _buildInfoRow(
                      Icons.link,
                      'Related To',
                      '${notification.relatedEntityType![0].toUpperCase()}${notification.relatedEntityType!.substring(1).replaceAll('_', ' ')} #${notification.relatedEntityId}',
                      Colors.teal,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metadata section (if present) showing parsed JSON details
            if (metadata != null && metadata.isNotEmpty)
              _buildMetadataSection(metadata),
            const SizedBox(height: 24),

            // Action buttons at the bottom of the detail view
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (notification.isRead) {
                        // Toggle back to unread (re-mark)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Already marked as read')),
                        );
                      } else {
                        service.markAsRead(notification.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as read')),
                        );
                      }
                    },
                    icon: Icon(
                      notification.isRead
                          ? Icons.mark_email_read
                          : Icons.mark_email_unread,
                    ),
                    label: Text(
                        notification.isRead ? 'Already Read' : 'Mark as Read'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      service.dismissNotification(notification.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Dismiss'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
