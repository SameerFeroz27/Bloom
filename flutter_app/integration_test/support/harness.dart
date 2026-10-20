import 'dart:ui' show Tristate;

import 'package:bloom/app.dart';
import 'package:bloom/models.dart';
import 'package:bloom/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Shared binding used by every native E2E test.
final IntegrationTestWidgetsFlutterBinding binding =
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// Must run before any `testWidgets` call so the integration binding wins over
/// the default live test binding. Top-level finals are lazy in Dart, so tests
/// call this first in `main()`.
void initHarness() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

final List<Map<String, dynamic>> _tests = <Map<String, dynamic>>[];
Map<String, dynamic>? _current;

String _slugify(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String get currentTestSlug => _current!['slug'] as String;

/// Registers a test that also records its outcome, steps and screenshots in a
/// JSON report that `test_driver/allure_driver.dart` writes on the host.
void registerTest(
  String suite,
  String name, {
  required String description,
  String severity = 'normal',
  List<String> tags = const <String>[],
  required Future<void> Function(WidgetTester tester) body,
}) {
  testWidgets(name, (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final Map<String, dynamic> record = <String, dynamic>{
      'name': name,
      'suite': suite,
      'description': description,
      'severity': severity,
      'tags': tags,
      'slug': _slugify('$suite $name'),
      'status': 'passed',
      'startedAt': DateTime.now().millisecondsSinceEpoch,
      'steps': <Map<String, dynamic>>[],
      'screenshots': <String>[],
    };
    _current = record;
    final Stopwatch watch = Stopwatch()..start();

    try {
      await body(tester);
    } catch (error, stack) {
      record['status'] = 'failed';
      record['message'] = error.toString();
      record['trace'] = stack.toString();
      try {
        await tester.pump(const Duration(milliseconds: 400));
        await _capture(tester, 'failure-state');
      } catch (_) {
        // A screenshot is evidence, never a reason to hide the real failure.
      }
      rethrow;
    } finally {
      record['durationMs'] = watch.elapsedMilliseconds;
      record['stoppedAt'] = DateTime.now().millisecondsSinceEpoch;
      semantics.dispose();
      _current = null;
      _tests.add(record);
      _publish();
    }
  });
}

void _publish() {
  binding.reportData ??= <String, dynamic>{};
  binding.reportData!['bloom_tests'] = _tests;
}

/// Records one user-visible step inside the current test.
Future<void> runStep(String name, Future<void> Function() body) async {
  final Map<String, dynamic> step = <String, dynamic>{
    'name': name,
    'status': 'passed',
    'startedAt': DateTime.now().millisecondsSinceEpoch,
  };
  final Stopwatch watch = Stopwatch()..start();
  try {
    await body();
  } catch (error) {
    step['status'] = 'failed';
    step['message'] = error.toString();
    rethrow;
  } finally {
    step['durationMs'] = watch.elapsedMilliseconds;
    step['stoppedAt'] = DateTime.now().millisecondsSinceEpoch;
    (_current!['steps'] as List<Map<String, dynamic>>).add(step);
  }
}

Future<void> _capture(WidgetTester tester, String label) async {
  await tester.pumpAndSettle();
  // Give the engine a beat to finish decoding assets before grabbing a frame.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await tester.pumpAndSettle();

  final String name = '$currentTestSlug--${_slugify(label)}';
  await binding.takeScreenshot(name);
  (_current!['screenshots'] as List<String>).add(name);

  final List<Map<String, dynamic>> steps = _current!['steps'] as List<Map<String, dynamic>>;
  if (steps.isNotEmpty) {
    steps.last['screenshot'] = name;
  }
}

/// Captures a screenshot and attaches it to the most recent step.
Future<void> capture(WidgetTester tester, String label) => _capture(tester, label);

/// Pumps the real app with a deterministic in-memory store and makes sure the
/// brand image is decoded before the first screenshot.
Future<BloomStore> startApp(WidgetTester tester, {BloomStore? store}) async {
  await binding.convertFlutterSurfaceToImage();
  final BloomStore bloom = store ?? BloomStore(sampleData());

  await tester.pumpWidget(BloomApp(store: bloom));
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/branding/bloom_logo.jpg'),
      tester.element(find.byType(BloomApp)),
    );
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  await tester.pumpAndSettle();

  return bloom;
}

Future<void> openTab(WidgetTester tester, String label) async {
  final Finder tab = find.bySemanticsLabel('Open $label tab');
  expect(tab, findsOneWidget, reason: 'The $label tab should be reachable by its label');
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

/// Scrolls a control into view before tapping it. Several dashboard cards sit
/// below the fold on a phone-sized screen.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Lets a snackbar finish its entrance animation so its text can be asserted.
Future<void> settleSnackBar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

/// Waits for transient snackbars so they do not cover the next screenshot.
Future<void> dismissSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

bool semanticsSelected(WidgetTester tester, Finder finder) {
  final SemanticsNode node = tester.getSemantics(finder);
  return node.flagsCollection.isSelected == Tristate.isTrue;
}

BloomStore storeWith({
  List<Task> tasks = const <Task>[],
  List<Habit> habits = const <Habit>[],
  List<Entry> entries = const <Entry>[],
  Map<String, Mood> moods = const <String, Mood>{},
  bool dark = false,
}) => BloomStore(
  StoreData(tasks: tasks, habits: habits, entries: entries, moods: moods, dark: dark),
);

Task sampleTask(
  String id,
  String title, {
  TaskCategory category = TaskCategory.personal,
  String time = '8:00 AM',
  bool done = false,
}) => Task(
  id: id,
  title: title,
  category: category,
  time: time,
  done: done,
  doneOn: done ? dateKey() : null,
);

Habit sampleHabit(
  String id,
  String title, {
  String subtitle = 'Every day',
  BloomIcon icon = BloomIcon.water,
  HabitTone tone = HabitTone.sky,
  HabitKind kind = HabitKind.build,
  bool doneToday = false,
}) => Habit(
  id: id,
  title: title,
  subtitle: subtitle,
  icon: icon,
  tone: tone,
  kind: kind,
  history: doneToday ? <String>[dateKey()] : <String>[],
);
