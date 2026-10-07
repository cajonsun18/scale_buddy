import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test: Skip-Perspektive', () {
    testWidgets('App durchlaeuft den Workflow ohne Entzerrung', (tester) async {
      // 1. App starten und Bild laden
      await startAppAndLoadImage(tester);

      // 2. Ueberspringe Perspektivenkorrektur und gehe in den naechsten Schritt wechseln
      await performSkipPerspectiveAndContinue(tester);

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
