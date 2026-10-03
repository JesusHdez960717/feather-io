/// Slows down brute force against the login, per IP: every failed attempt is
/// answered after [failureDelay] and, after [maxFailures] failures in a row,
/// the IP is locked for [lockDuration] (even if it then gets the credentials
/// right; otherwise it could just keep trying once the lock ends). A successful
/// login clears the failures, and failures older than [lockDuration] no longer
/// count.
///
/// It lives in memory: with several instances of the service, each one keeps
/// its own count.
class LoginRateLimiter {
  final int maxFailures;
  final Duration lockDuration;
  final Duration failureDelay;

  /// Clock and wait, replaceable in tests.
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  /// Above this many IPs, the ones that no longer count are forgotten.
  static const int _pruneAbove = 10000;

  final Map<String, _Attempts> _clients = {};

  LoginRateLimiter({
    this.maxFailures = 10,
    this.lockDuration = const Duration(minutes: 15),
    this.failureDelay = const Duration(seconds: 1),
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  /// What is left of [client]'s lock, or null if it may try.
  Duration? lockedFor(String client) {
    final until = _clients[client]?.lockedUntil;
    if (until == null) return null;
    final left = until.difference(_now());
    if (left > Duration.zero) return left;
    _clients.remove(client);
    return null;
  }

  /// Records a failed attempt of [client] (locking it when it reaches the
  /// maximum) and waits [failureDelay] before the response is sent.
  Future<void> failed(String client) async {
    final now = _now();
    final attempts = _clients[client];
    final stale =
        attempts == null ||
        now.difference(attempts.lastFailure) > lockDuration;
    final current = stale ? (_clients[client] = _Attempts(now)) : attempts;
    current
      ..failures += 1
      ..lastFailure = now;
    if (current.failures >= maxFailures) {
      current
        ..lockedUntil = now.add(lockDuration)
        ..failures = 0;
    }
    if (_clients.length > _pruneAbove) _prune(now);
    if (failureDelay > Duration.zero) await _wait(failureDelay);
  }

  /// A successful login: the previous failures no longer count.
  void succeeded(String client) => _clients.remove(client);

  void _prune(DateTime now) {
    _clients.removeWhere(
      (_, a) =>
          (a.lockedUntil == null || !a.lockedUntil!.isAfter(now)) &&
          now.difference(a.lastFailure) > lockDuration,
    );
  }
}

class _Attempts {
  int failures = 0;
  DateTime lastFailure;
  DateTime? lockedUntil;

  _Attempts(this.lastFailure);
}
