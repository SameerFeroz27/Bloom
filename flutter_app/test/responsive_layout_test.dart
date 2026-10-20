import 'package:bloom/app.dart';
import 'package:bloom/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app is phone-only, so every important card and sheet has to survive a
/// narrow 320 × 640 viewport without clipping or RenderFlex overflows.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BloomApp(store: BloomStore(sampleData())));
    await tester.pumpAndSettle();
  }

  testWidgets('hero stats stay readable on a small phone', (tester) async {
    await pumpAt(tester, const Size(320, 640));

    expect(find.text('Best active streak'), findsOneWidget);
    expect(find.text('Reflections kept'), findsOneWidget);
    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('1/4 tasks'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-run welcome fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BloomApp(store: BloomStore(emptyData())));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to bloom.'), findsOneWidget);
    expect(find.text('Add your first task'), findsOneWidget);
    expect(find.text('Create a habit'), findsOneWidget);
    expect(find.text('Three small ways to start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile sheet fits and its reset action is reachable', (tester) async {
    await pumpAt(tester, const Size(320, 640));
    final SemanticsHandle semantics = tester.ensureSemantics();

    try {
      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Add your name'), findsOneWidget);
      expect(find.text('Tasks done'), findsOneWidget);
      expect(find.text('Load sample data'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Load sample data'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('notification sheet fits and Got it is reachable', (tester) async {
    await pumpAt(tester, const Size(320, 640));
    final SemanticsHandle semantics = tester.ensureSemantics();

    try {
      await tester.tap(find.bySemanticsLabel('Notifications'));
      await tester.pumpAndSettle();

      expect(find.textContaining('right on track'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
