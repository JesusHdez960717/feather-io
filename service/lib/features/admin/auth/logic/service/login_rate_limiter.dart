/// Frena la fuerza bruta contra el login, por IP: cada intento fallido se
/// responde con [failureDelay] de retraso y, tras [maxFailures] fallos
/// seguidos, la IP queda bloqueada [lockDuration] (aunque luego acierte, si no
/// se podria seguir probando al acabar el bloqueo). Un login correcto borra
/// los fallos, y los fallos de hace mas de [lockDuration] ya no cuentan.
///
/// Vive en memoria: con varias instancias del servicio, cada una lleva su cuenta
class LoginRateLimiter {
  final int maxFailures;
  final Duration lockDuration;
  final Duration failureDelay;

  /// Reloj y espera, cambiables en los tests
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  /// Por encima de este numero de IPs se olvidan las que ya no cuentan
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

  /// Lo que le queda de bloqueo a [client], o null si puede intentarlo
  Duration? lockedFor(String client) {
    final until = _clients[client]?.lockedUntil;
    if (until == null) return null;
    final left = until.difference(_now());
    if (left > Duration.zero) return left;
    _clients.remove(client);
    return null;
  }

  /// Apunta un intento fallido de [client] (y lo bloquea si llega al maximo)
  /// y espera [failureDelay] antes de que se responda
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

  /// Un login correcto: los fallos anteriores ya no cuentan
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
