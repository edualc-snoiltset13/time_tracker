// lib/screens/settings/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:time_tracker/services/notification_service.dart';
import 'package:time_tracker/models/notification_preferences.dart';
import 'package:drift/drift.dart' as drift;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  File? _logo;
  bool _showLetterhead = true;

  // Notification preference state
  NotificationPreference? _notifPrefs;
  bool _notifTimerStop = true;
  bool _notifDeadlineReminders = true;
  bool _notifTimeLimitWarnings = true;
  bool _notifWeeklySummary = true;
  bool _notifInvoiceOverdue = true;
  bool _notifTaskOverdue = true;
  bool _notifMilestones = true;
  bool _notifSoundEnabled = true;
  bool _notifVibrationEnabled = true;
  int _deadlineReminderMinutes = 60;
  int _timeLimitWarningPercent = 80;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotificationPreferences();
  }

  Future<void> _loadSettings() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final settings = await (db.select(db.companySettings)..where((s) => s.id.equals(1))).getSingleOrNull();
    if (settings != null) {
      _nameController.text = settings.companyName;
      _addressController.text = settings.companyAddress;
      // FIX: Corrected typo from logoPath to logoPath and handled null
      if (settings.logoPath != null) {
        _logo = File(settings.logoPath!);
      }
      _showLetterhead = settings.showLetterhead;
      setState(() {});
    }
  }

  Future<void> _loadNotificationPreferences() async {
    final service = Provider.of<NotificationService>(context, listen: false);
    final prefs = await service.getPreferences();
    if (prefs != null && mounted) {
      setState(() {
        _notifPrefs = prefs;
        _notifTimerStop = prefs.timerStopNotifications;
        _notifDeadlineReminders = prefs.deadlineReminders;
        _notifTimeLimitWarnings = prefs.timeLimitWarnings;
        _notifWeeklySummary = prefs.weeklySummary;
        _notifInvoiceOverdue = prefs.invoiceOverdueAlerts;
        _notifTaskOverdue = prefs.taskOverdueAlerts;
        _notifMilestones = prefs.milestoneNotifications;
        _notifSoundEnabled = prefs.soundEnabled;
        _notifVibrationEnabled = prefs.vibrationEnabled;
        _deadlineReminderMinutes = prefs.deadlineReminderMinutes;
        _timeLimitWarningPercent = prefs.timeLimitWarningPercent;
      });
    }
  }

  Future<void> _saveNotificationPreferences() async {
    final service = Provider.of<NotificationService>(context, listen: false);
    await service.updatePreferences(
      NotificationPreferencesCompanion(
        id: const drift.Value(1),
        timerStopNotifications: drift.Value(_notifTimerStop),
        deadlineReminders: drift.Value(_notifDeadlineReminders),
        timeLimitWarnings: drift.Value(_notifTimeLimitWarnings),
        weeklySummary: drift.Value(_notifWeeklySummary),
        invoiceOverdueAlerts: drift.Value(_notifInvoiceOverdue),
        taskOverdueAlerts: drift.Value(_notifTaskOverdue),
        milestoneNotifications: drift.Value(_notifMilestones),
        soundEnabled: drift.Value(_notifSoundEnabled),
        vibrationEnabled: drift.Value(_notifVibrationEnabled),
        deadlineReminderMinutes: drift.Value(_deadlineReminderMinutes),
        timeLimitWarningPercent: drift.Value(_timeLimitWarningPercent),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved.')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logo = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final db = Provider.of<AppDatabase>(context, listen: false);
    final companion = CompanySettingsCompanion(
      id: const drift.Value(1),
      companyName: drift.Value(_nameController.text),
      companyAddress: drift.Value(_addressController.text),
      // FIX: Corrected typo from logoPath to logoPath
      logoPath: _logo != null ? drift.Value(_logo!.path) : const drift.Value.absent(),
      showLetterhead: drift.Value(_showLetterhead),
    );

    await db.into(db.companySettings).insertOnConflictUpdate(companion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) => value!.isEmpty ? 'Please enter your company name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Company Address'),
              maxLines: 3,
              validator: (value) => value!.isEmpty ? 'Please enter your company address' : null,
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Company Logo'),
              subtitle: _logo == null ? const Text('No logo selected') : Text(_logo!.path.split('/').last),
              trailing: const Icon(Icons.image),
              onTap: _pickLogo,
            ),
            if (_logo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Image.file(_logo!, height: 100),
              ),
            SwitchListTile(
              title: const Text('Show Letterhead on Invoices'),
              subtitle: const Text('Includes your logo and company details at the top.'),
              value: _showLetterhead,
              onChanged: (bool value) {
                setState(() {
                  _showLetterhead = value;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),

            // ---- Notification Preferences Section ----
            const Divider(height: 48, thickness: 2),
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure which notifications you receive and how they behave.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Notification type toggles
            Card(
              child: Column(
                children: [
                  _buildNotificationToggle(
                    'Timer Completion',
                    'Get notified when a timer is stopped with task details and duration.',
                    Icons.timer_off,
                    _notifTimerStop,
                    (v) => setState(() => _notifTimerStop = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Deadline Reminders',
                    'Receive advance warnings before task deadlines.',
                    Icons.warning_amber_rounded,
                    _notifDeadlineReminders,
                    (v) => setState(() => _notifDeadlineReminders = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Time Limit Warnings',
                    'Get alerted when project hours approach monthly limits.',
                    Icons.hourglass_bottom,
                    _notifTimeLimitWarnings,
                    (v) => setState(() => _notifTimeLimitWarnings = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Weekly Summary',
                    'Receive a weekly productivity report with hours, earnings, and tasks.',
                    Icons.summarize,
                    _notifWeeklySummary,
                    (v) => setState(() => _notifWeeklySummary = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Invoice Overdue Alerts',
                    'Get notified when invoices pass their due date.',
                    Icons.receipt_long,
                    _notifInvoiceOverdue,
                    (v) => setState(() => _notifInvoiceOverdue = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Task Overdue Alerts',
                    'Receive alerts for tasks past their deadline.',
                    Icons.assignment_late,
                    _notifTaskOverdue,
                    (v) => setState(() => _notifTaskOverdue = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Milestone Celebrations',
                    'Celebrate when reaching hour milestones on projects.',
                    Icons.emoji_events,
                    _notifMilestones,
                    (v) => setState(() => _notifMilestones = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Threshold settings
            Text(
              'Thresholds',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline Reminder Lead Time',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NotificationPreferenceDefinitions.getDeadlineReminderLabel(
                          _deadlineReminderMinutes),
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    Slider(
                      value: _deadlineReminderMinutes.toDouble(),
                      min: 15,
                      max: 1440,
                      divisions: 19,
                      label: NotificationPreferenceDefinitions
                          .getDeadlineReminderLabel(_deadlineReminderMinutes),
                      onChanged: (v) {
                        setState(() => _deadlineReminderMinutes = v.round());
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Time Limit Warning Threshold',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NotificationPreferenceDefinitions.getTimeLimitLabel(
                          _timeLimitWarningPercent),
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    Slider(
                      value: _timeLimitWarningPercent.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 10,
                      label: '$_timeLimitWarningPercent%',
                      onChanged: (v) {
                        setState(() => _timeLimitWarningPercent = v.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sound & Vibration
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildNotificationToggle(
                    'Sound',
                    'Play a sound when notifications are created.',
                    Icons.volume_up,
                    _notifSoundEnabled,
                    (v) => setState(() => _notifSoundEnabled = v),
                  ),
                  const Divider(height: 1),
                  _buildNotificationToggle(
                    'Vibration',
                    'Vibrate when notifications are created.',
                    Icons.vibration,
                    _notifVibrationEnabled,
                    (v) => setState(() => _notifVibrationEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveNotificationPreferences,
              child: const Text('Save Notification Preferences'),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}