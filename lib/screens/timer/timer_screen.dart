// lib/screens/timer/timer_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            color: Colors.transparent,
            child: TabBar(
              indicatorColor: Colors.tealAccent,
              labelColor: Colors.tealAccent,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.hourglass_bottom), text: 'Countdown'),
                Tab(icon: Icon(Icons.timer_outlined), text: 'Stopwatch'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _CountdownTab(),
                _StopwatchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownTab extends StatefulWidget {
  const _CountdownTab();

  @override
  State<_CountdownTab> createState() => _CountdownTabState();
}

class _CountdownTabState extends State<_CountdownTab> {
  static const _tick = Duration(milliseconds: 100);

  Duration _initial = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  Timer? _timer;
  DateTime? _endsAt;
  bool _alarmShown = false;

  bool get _isRunning => _timer != null;
  bool get _isFinished => _remaining == Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_remaining == Duration.zero) return;
    _alarmShown = false;
    _endsAt = DateTime.now().add(_remaining);
    _timer = Timer.periodic(_tick, (_) {
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        _timer = null;
        _onFinished();
      } else {
        setState(() => _remaining = left);
      }
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _alarmShown = false;
    setState(() => _remaining = _initial);
  }

  void _onFinished() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    if (_alarmShown || !mounted) return;
    _alarmShown = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Time is up'),
        content: Text('Your ${_format(_initial)} timer has finished.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _reset();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDuration() async {
    if (_isRunning) return;
    final picked = await showDialog<Duration>(
      context: context,
      builder: (_) => _DurationPickerDialog(initial: _initial),
    );
    if (picked != null && picked > Duration.zero) {
      setState(() {
        _initial = picked;
        _remaining = picked;
        _alarmShown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _editDuration,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFinished ? Colors.redAccent : Colors.tealAccent,
                  width: 2,
                ),
              ),
              child: Text(
                _format(_remaining),
                style: const TextStyle(
                  fontSize: 72,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRunning ? 'Running' : (_isFinished ? 'Finished' : 'Tap time to set'),
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.refresh,
                label: 'Reset',
                onPressed: _reset,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 24),
              _RoundButton(
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                label: _isRunning ? 'Pause' : 'Start',
                onPressed: _isFinished
                    ? null
                    : (_isRunning ? _pause : _start),
                color: Colors.tealAccent,
                foreground: Colors.black,
                large: true,
              ),
              const SizedBox(width: 24),
              _RoundButton(
                icon: Icons.edit,
                label: 'Set',
                onPressed: _isRunning ? null : _editDuration,
                color: Colors.grey.shade700,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: [
              _PresetChip(label: '1 min', duration: const Duration(minutes: 1), onSelected: _applyPreset),
              _PresetChip(label: '5 min', duration: const Duration(minutes: 5), onSelected: _applyPreset),
              _PresetChip(label: '10 min', duration: const Duration(minutes: 10), onSelected: _applyPreset),
              _PresetChip(label: '25 min', duration: const Duration(minutes: 25), onSelected: _applyPreset),
              _PresetChip(label: '1 hr', duration: const Duration(hours: 1), onSelected: _applyPreset),
            ],
          ),
        ],
      ),
    );
  }

  void _applyPreset(Duration d) {
    if (_isRunning) return;
    setState(() {
      _initial = d;
      _remaining = d;
      _alarmShown = false;
    });
  }
}

class _StopwatchTab extends StatefulWidget {
  const _StopwatchTab();

  @override
  State<_StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<_StopwatchTab> {
  final Stopwatch _sw = Stopwatch();
  final List<Duration> _laps = [];
  Timer? _ticker;

  bool get _isRunning => _sw.isRunning;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _sw.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _pause() {
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
    setState(() {});
  }

  void _reset() {
    _sw.stop();
    _sw.reset();
    _ticker?.cancel();
    _ticker = null;
    _laps.clear();
    setState(() {});
  }

  void _lap() {
    if (!_isRunning) return;
    setState(() => _laps.insert(0, _sw.elapsed));
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _sw.elapsed;
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          _formatPrecise(elapsed),
          style: const TextStyle(
            fontSize: 64,
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(
              icon: Icons.refresh,
              label: 'Reset',
              onPressed: (elapsed == Duration.zero && !_isRunning) ? null : _reset,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 24),
            _RoundButton(
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              label: _isRunning ? 'Pause' : 'Start',
              onPressed: _isRunning ? _pause : _start,
              color: Colors.tealAccent,
              foreground: Colors.black,
              large: true,
            ),
            const SizedBox(width: 24),
            _RoundButton(
              icon: Icons.flag,
              label: 'Lap',
              onPressed: _isRunning ? _lap : null,
              color: Colors.grey.shade700,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        Expanded(
          child: _laps.isEmpty
              ? Center(
                  child: Text(
                    'No laps yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _laps.length,
                  itemBuilder: (_, i) {
                    final lapNumber = _laps.length - i;
                    final lapTime = _laps[i];
                    final prevTotal = i == _laps.length - 1
                        ? Duration.zero
                        : _laps[i + 1];
                    final split = lapTime - prevTotal;
                    return ListTile(
                      dense: true,
                      leading: Text('Lap $lapNumber'),
                      title: Text(_formatPrecise(split)),
                      trailing: Text(
                        _formatPrecise(lapTime),
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DurationPickerDialog extends StatefulWidget {
  const _DurationPickerDialog({required this.initial});
  final Duration initial;

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.initial.inHours;
    _minutes = widget.initial.inMinutes.remainder(60);
    _seconds = widget.initial.inSeconds.remainder(60);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set duration'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NumberWheel(label: 'h', value: _hours, max: 23, onChanged: (v) => setState(() => _hours = v)),
          const Text(' : ', style: TextStyle(fontSize: 24)),
          _NumberWheel(label: 'm', value: _minutes, max: 59, onChanged: (v) => setState(() => _minutes = v)),
          const Text(' : ', style: TextStyle(fontSize: 24)),
          _NumberWheel(label: 's', value: _seconds, max: 59, onChanged: (v) => setState(() => _seconds = v)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            Duration(hours: _hours, minutes: _minutes, seconds: _seconds),
          ),
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class _NumberWheel extends StatelessWidget {
  const _NumberWheel({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () => onChanged(value >= max ? 0 : value + 1),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => onChanged(value <= 0 ? max : value - 1),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500])),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.foreground = Colors.white,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 80.0 : 64.0;
    final disabled = onPressed == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: disabled ? Colors.grey.shade800 : color,
              foregroundColor: disabled ? Colors.grey.shade600 : foreground,
              padding: EdgeInsets.zero,
            ),
            onPressed: onPressed,
            child: Icon(icon, size: large ? 36 : 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.duration,
    required this.onSelected,
  });

  final String label;
  final Duration duration;
  final ValueChanged<Duration> onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onSelected(duration),
    );
  }
}

String _format(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
  return '$m:$s';
}

String _formatPrecise(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
  if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s.$cs';
  return '$m:$s.$cs';
}
