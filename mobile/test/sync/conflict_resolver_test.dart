import 'package:flutter_test/flutter_test.dart';
import 'package:inmovisita/features/sync/domain/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();

  RegistroVersionado registro({
    int revision = 1,
    int updatedAt = 1000,
  }) {
    return RegistroVersionado(
      id: 'v-1',
      revision: revision,
      updatedAt: updatedAt,
    );
  }

  group('ConflictResolver', () {
    test('sin diferencias no hay nada que aplicar', () {
      final decision = resolver.resolver(
        local: registro(),
        remoto: registro(),
        localModificadoLocalmente: false,
      );

      expect(decision, DecisionConflicto.sinCambios);
    });

    test('gana el servidor cuando su revision es mayor y no hay cambios locales',
        () {
      final decision = resolver.resolver(
        local: registro(revision: 3, updatedAt: 5000),
        remoto: registro(revision: 4, updatedAt: 4000),
        localModificadoLocalmente: false,
      );

      expect(decision, DecisionConflicto.aplicarRemoto);
    });

    test('escritura concurrente real se marca como conflicto', () {
      final decision = resolver.resolver(
        local: registro(revision: 3, updatedAt: 9000),
        remoto: registro(revision: 4, updatedAt: 4000),
        localModificadoLocalmente: true,
      );

      expect(decision, DecisionConflicto.marcarConflicto);
    });

    test('gana el dispositivo cuando su revision es mayor', () {
      final decision = resolver.resolver(
        local: registro(revision: 5, updatedAt: 1000),
        remoto: registro(revision: 4, updatedAt: 8000),
        localModificadoLocalmente: true,
      );

      expect(decision, DecisionConflicto.conservarLocal);
    });

    test('con la misma revision desempata la marca de tiempo', () {
      final decision = resolver.resolver(
        local: registro(revision: 2, updatedAt: 9000),
        remoto: registro(revision: 2, updatedAt: 3000),
        localModificadoLocalmente: true,
      );

      expect(decision, DecisionConflicto.conservarLocal);
    });

    test('una diferencia de reloj menor a la tolerancia se ignora', () {
      final decision = resolver.resolver(
        local: registro(revision: 2, updatedAt: 10000),
        remoto: registro(revision: 2, updatedAt: 10500),
        localModificadoLocalmente: true,
      );

      expect(decision, DecisionConflicto.sinCambios);
    });
  });
}
