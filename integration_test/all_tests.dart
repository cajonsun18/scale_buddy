import 'package:integration_test/integration_test.dart';

import 'e2e_auto_perspective_workflow_test.dart' as auto_test;
import 'e2e_manual_perspective_workflow_test.dart' as manual_test;
import 'e2e_mobile_image_load_workflow_test.dart' as mobile_test;
import 'e2e_skip_perspective_test.dart' as skip_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Führt alle Integrationstests nacheinander in einer Session aus
  auto_test.main();
  manual_test.main();
  mobile_test.main();
  skip_test.main();
}
