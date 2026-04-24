// lib/services/idle_service.dart
class IdleService {
  static const Duration defaultIdleThreshold = Duration(minutes: 5);

  final Duration idleThreshold;
  DateTime _lastActivity = DateTime.now();

  IdleService({this.idleThreshold = defaultIdleThreshold});

  DateTime get lastActivity => _lastActivity;

  bool get isIdle =>
      DateTime.now().difference(_lastActivity) >= idleThreshold;

  void recordActivity() {
    _lastActivity = DateTime.now();
  }
}
