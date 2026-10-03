@TestOn('vm')
library;

import 'package:service/feather.dart';
import 'package:test/test.dart';

void main() {
  group('LoginRateLimiter', () {
    late DateTime now;
    late List<Duration> waits;
    late LoginRateLimiter limiter;

    setUp(() {
      now = DateTime(2026, 10, 3, 12);
      waits = [];
      limiter = LoginRateLimiter(
        maxFailures: 3,
        lockDuration: const Duration(minutes: 15),
        failureDelay: const Duration(seconds: 1),
        now: () => now,
        wait: (d) async => waits.add(d),
      );
    });

    Future<void> fail(String client, int times) async {
      for (var i = 0; i < times; i++) {
        await limiter.failed(client);
      }
    }

    test('Should wait the penalty on every failure', () async {
      await fail('1.1.1.1', 2);
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    });

    test('Should lock a client after the maximum of failures', () async {
      await fail('1.1.1.1', 2);
      expect(limiter.lockedFor('1.1.1.1'), isNull);
      await fail('1.1.1.1', 1);
      expect(limiter.lockedFor('1.1.1.1'), const Duration(minutes: 15));
    });

    test('Should unlock the client when the lock ends', () async {
      await fail('1.1.1.1', 3);
      now = now.add(const Duration(minutes: 14));
      expect(limiter.lockedFor('1.1.1.1'), const Duration(minutes: 1));
      now = now.add(const Duration(minutes: 1));
      expect(limiter.lockedFor('1.1.1.1'), isNull);
      //y empieza de cero
      await fail('1.1.1.1', 2);
      expect(limiter.lockedFor('1.1.1.1'), isNull);
    });

    test('Should forget the failures after a successful login', () async {
      await fail('1.1.1.1', 2);
      limiter.succeeded('1.1.1.1');
      await fail('1.1.1.1', 2);
      expect(limiter.lockedFor('1.1.1.1'), isNull);
    });

    test('Should not count failures older than the lock duration', () async {
      await fail('1.1.1.1', 2);
      now = now.add(const Duration(minutes: 16));
      await fail('1.1.1.1', 2);
      expect(limiter.lockedFor('1.1.1.1'), isNull);
    });

    test('Should keep each client apart', () async {
      await fail('1.1.1.1', 3);
      expect(limiter.lockedFor('1.1.1.1'), isNotNull);
      expect(limiter.lockedFor('2.2.2.2'), isNull);
    });
  });
}
