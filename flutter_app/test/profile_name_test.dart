import 'package:bloom/app.dart';
import 'package:bloom/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Focused coverage for the Profile name action: add, edit, clear, and the
/// effect on the Home greeting. Run on its own with:
///   flutter test test/profile_name_test.dart
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('user can add, edit and clear their name from Profile', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final BloomStore store = BloomStore(sampleData());
    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Add your name'), findsOneWidget);

      // Add a name.
      await tester.tap(find.text('Add your name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Sam');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(store.name, 'Sam');
      expect(store.toJson()['name'], 'Sam');
      expect(find.text('Sam'), findsOneWidget);

      // The greeting uses the new name.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.textContaining(', Sam.'), findsOneWidget);

      // Edit the name.
      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Samar');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(store.name, 'Samar');
      expect(find.text('Samar'), findsOneWidget);

      // Clearing it returns to the anonymous greeting.
      await tester.tap(find.text('Samar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(store.name, '');
      expect(find.text('Add your name'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.textContaining(', Samar.'), findsNothing);
      expect(find.textContaining(', Sam.'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
