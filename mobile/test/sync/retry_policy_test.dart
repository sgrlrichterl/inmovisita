import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inmovisita/features/sync/domain/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    const politica = RetryPolicy();

    test('la espera crece de forma exponencial', () {
      expect(politica.esperaPara(0).inSeconds, 5);
      expect(politica.esperaPara(1).inSeconds, 10);
      expect(politica.esperaPara(2).inSeconds, 20);
      expect(politica.esperaPara(3).inSeconds, 40);
    });

    test('la espera nunca supera el tope configurado', () {
      expect(
        politica.esperaPara(30).inMilliseconds,
        lessThanOrEqualTo(politica.maxDelay.inMilliseconds),
      );
    });

    test('el jitter mantiene la espera dentro de +-20%', () {
      final aleatorio = Random(42);
      for (var intento = 0; intento < 5; intento++) {
        final base = politica.esperaPara(intento).inMilliseconds;
        final conJitter =
            politica.esperaPara(intento, random: aleatorio).inMilliseconds;
        expect(conJitter, greaterThanOrEqualTo((base * 0.8).floor()));
        expect(conJitter, lessThanOrEqualTo((base * 1.2).ceil()));
      }
    });

    test('deja de reintentar al alcanzar el maximo', () {
      expect(politica.debeReintentar(4), isTrue);
      expect(politica.debeReintentar(5), isFalse);
      expect(politica.debeReintentar(6), isFalse);
    });
  });
}
