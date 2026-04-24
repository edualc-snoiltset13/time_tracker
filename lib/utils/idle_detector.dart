// lib/utils/idle_detector.dart
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

/// Wraps a subtree and watches for user inactivity while a timer is running.
///
/// Pointer and hardware-key events reset the idle clock. When the user is idle
/// longer than [idleThreshold] and a [TimeEntry] with no end time exists, a
/// dialog asks whether to keep or discard the idle period.
class IdleDetector extends StatefulWidget {
  final Widget child;
  final Duration idleThreshold;
  final Duration checkInterval;

  const IdleDetector({
    super.key,
    required this.child,
    this.idleThreshold = const Duration(minutes: 5),
    this.checkInterval = const Duration(seconds: 30),
  });

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector>
    with WidgetsBindingObserver {
  DateTime _lastActivity = DateTime.now();
  Timer? _checkTimer;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _checkTimer = Timer.periodic(widget.checkInterval, (_) => _checkIdle());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app returns to the foreground, the in-app timer was paused so
    // we may have missed an idle window — check right away.
    if (state == AppLifecycleState.resumed) {
      _checkIdle();
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    _registerActivity();
    return false;
  }

  void _registerActivity() {
    _lastActivity = DateTime.now();
  }

  Future<void> _checkIdle() async {
    if (_dialogShowing || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastActivity) < widget.idleThreshold) return;

    final db = Provider.of<AppDatabase>(context, listen: false);
    final activeEntries = await (db.select(db.timeEntries)
          ..where((t) => t.endTime.isNull())
          ..limit(1))
        .get();
    if (activeEntries.isEmpty) return;

    final entry = activeEntries.first;
    // Never claim idle time from before the timer actually started.
    final idleSince = entry.startTime.isAfter(_lastActivity)
        ? entry.startTime
        : _lastActivity;
    final idleDuration = now.difference(idleSince);
    if (idleDuration < widget.idleThreshold) return;

    if (!mounted) return;
    _dialogShowing = true;
    final choice = await showDialog<_IdleChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IdleDialog(
        idleSince: idleSince,
        idleDuration: idleDuration,
      ),
    );
    _dialogShowing = false;
    _registerActivity();

    if (!mounted || choice == null) return;
    switch (choice) {
      case _IdleChoice.keep:
        break;
      case _IdleChoice.discard:
        await (db.update(db.timeEntries)..where((t) => t.id.equals(entry.id)))
            .write(TimeEntriesCompanion(endTime: Value(idleSince)));
        break;
      case _IdleChoice.discardAndContinue:
        await (db.update(db.timeEntries)..where((t) => t.id.equals(entry.id)))
            .write(TimeEntriesCompanion(endTime: Value(idleSince)));
        await db.into(db.timeEntries).insert(TimeEntriesCompanion(
              projectId: Value(entry.projectId),
              description: Value(entry.description),
              category: Value(entry.category),
              isBillable: Value(entry.isBillable),
              startTime: Value(DateTime.now()),
            ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerActivity(),
      onPointerMove: (_) => _registerActivity(),
      onPointerHover: (_) => _registerActivity(),
      onPointerSignal: (_) => _registerActivity(),
      child: widget.child,
    );
  }
}

enum _IdleChoice { keep, discard, discardAndContinue }

class _IdleDialog extends StatelessWidget {
  final DateTime idleSince;
  final Duration idleDuration;

  const _IdleDialog({required this.idleSince, required this.idleDuration});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final since = TimeOfDay.fromDateTime(idleSince).format(context);
    return AlertDialog(
      title: const Text('Are you still there?'),
      content: Text(
        'Your timer has been running but no activity has been detected '
        'since $since (about ${_formatDuration(idleDuration)} ago).\n\n'
        'What would you like to do with the idle time?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _IdleChoice.keep),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _IdleChoice.discard),
          child: const Text('Discard & stop'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _IdleChoice.discardAndContinue),
          child: const Text('Discard & continue'),
        ),
      ],
    );
  }
}
