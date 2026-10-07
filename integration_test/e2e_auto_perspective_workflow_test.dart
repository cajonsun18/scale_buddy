import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test: Auto-Perspektive Workflow', () {
    testWidgets('App durchlaeuft den Workflow mit automatischer Entzerrung', (
      tester,
    ) async {
      // 1. App starten und Bild laden
      await startAppAndLoadImage(tester);

      // 2. Automatische Perspektivenkorrektur anwenden und in den naechsten Schritt wechseln
      await performAutoPerspectiveAndContinue(tester);

      // 3. Kalibrieren
      await performCalibrationAndContinue(tester);

      // 4. Messen
      await performMeasurementsAndContinue(tester);

      // 5. Export
      await performExport(tester);

      // Pausiere am Ende des Tests fuer 4 Sekunden
      await Future.delayed(const Duration(seconds: 4));
    });
  });
}
