import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver for the native Android E2E suite.
///
/// It receives screenshots and the structured test report from the app, writes
/// both into `e2e/artifacts/`, and lets `flutter drive` exit with the test status.
Future<void> main() async {
  final screenshotDir = Directory('../e2e/artifacts/screenshots');
  await screenshotDir.create(recursive: true);

  await integrationDriver(
    onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
      final file = File('${screenshotDir.path}/$name.png');
      await file.writeAsBytes(image, flush: true);
      stdout.writeln('Saved screenshot ${file.path}');
      return true;
    },
    responseDataCallback: (Map<String, dynamic>? data) async {
      final file = File('../e2e/artifacts/integration_response_data.json');
      await file.parent.create(recursive: true);
      final report = Map<String, dynamic>.from(data ?? <String, dynamic>{});
      // The bytes are already written as files by onScreenshot.
      report.remove('screenshots');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      stdout.writeln('Saved test report ${file.path}');
    },
    writeResponseOnFailure: true,
  );
}
