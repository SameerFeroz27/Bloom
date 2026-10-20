import 'package:bloom/app.dart';
import 'package:bloom/models.dart';
import 'package:bloom/store.dart';
import 'package:bloom/widgets/rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Home keeps only unfinished work, so checking something off pulls the next
/// item up into the list.
void main() {
  setUpAll(() {
    // Tests run offline; do not try to download the fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  BloomStore storeWith({
    List<Task> tasks = const [],
    List<Habit> habits = const [],
  }) => BloomStore(
    StoreData(tasks: tasks, habits: habits, entries: [], moods: {}, dark: false),
  );

  Task task(String id, String title) =>
      Task(id: id, title: title, category: TaskCategory.personal, time: '8:00 AM');

  Habit habit(String id, String title, {bool doneToday = false}) => Habit(
    id: id,
    title: title,
    subtitle: 'Every day',
    icon: BloomIcon.water,
    tone: HabitTone.sky,
    kind: HabitKind.build,
    history: doneToday ? [dateKey()] : const [],
  );

  testWidgets('finishing a task removes it and shows the next one', (tester) async {
    final store = storeWith(
      tasks: [
        task('t1', 'Task one'),
        task('t2', 'Task two'),
        task('t3', 'Task three'),
        task('t4', 'Task four'),
      ],
    );

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    // Only the first three fit.
    expect(find.text('Task one'), findsOneWidget);
    expect(find.text('Task two'), findsOneWidget);
    expect(find.text('Task three'), findsOneWidget);
    expect(find.text('Task four'), findsNothing);

    // Tick the first one off.
    store.toggleTask('t1');
    await tester.pumpAndSettle();

    expect(find.text('Task one'), findsNothing);
    expect(find.text('Task four'), findsOneWidget);
  });

  testWidgets('tasks already done never appear on home', (tester) async {
    final store = storeWith(
      tasks: [
        Task(
          id: 't1',
          title: 'Already done',
          category: TaskCategory.personal,
          time: '8:00 AM',
          done: true,
          doneOn: dateKey(),
        ),
        task('t2', 'Still open'),
      ],
    );

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Already done'), findsNothing);
    expect(find.text('Still open'), findsOneWidget);
  });

  testWidgets('checking a habit removes it and shows the next one', (tester) async {
    final store = storeWith(
      habits: [
        habit('h1', 'Habit one'),
        habit('h2', 'Habit two'),
        habit('h3', 'Habit three'),
        habit('h4', 'Habit four'),
      ],
    );

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Habit one'), findsOneWidget);
    expect(find.text('Habit two'), findsOneWidget);
    expect(find.text('Habit three'), findsOneWidget);
    expect(find.text('Habit four'), findsNothing);

    store.toggleHabitToday('h1');
    await tester.pumpAndSettle();

    expect(find.text('Habit one'), findsNothing);
    expect(find.text('Habit four'), findsOneWidget);
  });

  testWidgets('habits already done today never appear on home', (tester) async {
    final store = storeWith(
      habits: [
        habit('h1', 'Done already', doneToday: true),
        habit('h2', 'Not yet'),
      ],
    );

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Done already'), findsNothing);
    expect(find.text('Not yet'), findsOneWidget);
  });

  testWidgets('home shows an all-clear message when nothing is left', (tester) async {
    final store = storeWith(
      tasks: [
        Task(
          id: 't1',
          title: 'Only task',
          category: TaskCategory.personal,
          time: '8:00 AM',
          done: true,
          doneOn: dateKey(),
        ),
      ],
      habits: [habit('h1', 'Only habit', doneToday: true)],
    );

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('All done for today'), findsOneWidget);
  });

  testWidgets('tapping the home checkbox still completes the task', (tester) async {
    final store = storeWith(tasks: [task('t1', 'Task one'), task('t2', 'Task two')]);

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    // The row tap is deferred until the exit animation finishes, so this also
    // guards against the completion being lost.
    final checkbox = find
        .descendant(
          of: find.ancestor(of: find.text('Task one'), matching: find.byType(TaskRow)),
          matching: find.byType(GestureDetector),
        )
        .first;

    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    expect(store.tasks.firstWhere((t) => t.id == 't1').done, isTrue);
    expect(find.text('Task one'), findsNothing);
    expect(find.text('Task two'), findsOneWidget);
  });

  testWidgets('tapping the home habit button still checks it off', (tester) async {
    final store = storeWith(habits: [habit('h1', 'Habit one'), habit('h2', 'Habit two')]);

    await tester.pumpWidget(BloomApp(store: store));
    await tester.pumpAndSettle();

    // The habits card sits below the fold on the default test surface.
    await tester.ensureVisible(find.text('Habit one'));
    await tester.pumpAndSettle();

    final button = find
        .descendant(
          of: find.ancestor(of: find.text('Habit one'), matching: find.byType(Row)).first,
          matching: find.byType(GestureDetector),
        )
        .first;

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(store.habits.firstWhere((h) => h.id == 'h1').history, contains(dateKey()));
    expect(find.text('Habit one'), findsNothing);
    expect(find.text('Habit two'), findsOneWidget);
  });
}
