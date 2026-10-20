import 'package:bloom/models.dart';
import 'package:bloom/store.dart';
import 'package:bloom/widgets/common.dart';
import 'package:bloom/widgets/sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/harness.dart';

void main() {
  initHarness();

  setUpAll(() {
    // The suite must be deterministic and independent of the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ------------------------------------------------------- app shell

  registerTest(
    'App shell & navigation',
    'Home shows the branded dashboard',
    description:
        'Launches the native app and checks the new bloom logo, greeting, '
        'progress rings and the main dashboard sections.',
    severity: 'critical',
    tags: <String>['smoke', 'branding', 'home'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);

      await runStep('The app opens on Home with the new logo and greeting', () async {
        expect(find.text('bloom.'), findsOneWidget);
        expect(find.bySemanticsLabel('bloom logo'), findsOneWidget);
        expect(find.text('A LITTLE BETTER, EVERY DAY'), findsOneWidget);
        expect(find.textContaining('Good '), findsOneWidget);
        expect(find.textContaining('Make room for a better you.'), findsOneWidget);
      });

      await runStep('The dashboard shows live progress and all main sections', () async {
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('1/4 tasks'), findsOneWidget);
        expect(find.text("Today's focus"), findsOneWidget);
        expect(find.text('Your daily habits'), findsOneWidget);
        expect(find.text('A fresh week'), findsOneWidget);
        expect(store.tasks.length, 4);
        expect(store.habits.length, 4);
      });

      await capture(tester, 'home dashboard');
    },
  );

  registerTest(
    'App shell & navigation',
    'Bottom navigation opens every section',
    description:
        'Walks through all five tabs and verifies each screen renders its '
        'headline and primary content.',
    severity: 'critical',
    tags: <String>['smoke', 'navigation'],
    body: (WidgetTester tester) async {
      await startApp(tester);

      await runStep('Tasks section', () async {
        await openTab(tester, 'Tasks');
        expect(find.text('My tasks'), findsOneWidget);
        expect(find.text('Search your tasks'), findsOneWidget);
      });
      await capture(tester, 'tasks section');

      await runStep('Habits section', () async {
        await openTab(tester, 'Habits');
        expect(find.text('Habits'), findsWidgets);
        expect(find.text('SMALL HABITS, LASTING CHANGE'), findsOneWidget);
        expect(find.text('2 of 4 done today'), findsOneWidget);
      });
      await capture(tester, 'habits section');

      await runStep('Journal section', () async {
        await openTab(tester, 'Journal');
        expect(find.text('Journal'), findsWidgets);
        expect(find.text("What's on your mind today?"), findsOneWidget);
        expect(find.text('Save reflection'), findsOneWidget);
      });
      await capture(tester, 'journal section');

      await runStep('Insights section', () async {
        await openTab(tester, 'Insights');
        expect(find.text('Insights'), findsWidgets);
        expect(find.text('Your last two weeks, at a glance.'), findsOneWidget);
        expect(find.text('Every small step counts'), findsOneWidget);
      });
      await capture(tester, 'insights section');

      await runStep('Back to Home', () async {
        await openTab(tester, 'Home');
        expect(find.text("Today's focus"), findsOneWidget);
      });
      await capture(tester, 'back home');
    },
  );

  // ----------------------------------------------------------- tasks

  registerTest(
    'Tasks',
    'Create a task from the add button',
    description:
        'Creates a work task through the bottom sheet and verifies it appears '
        'at the top of the task list with the chosen category and time.',
    severity: 'critical',
    tags: <String>['crud', 'tasks'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      final Finder sheet = find.byType(NewTaskSheet);

      await runStep('Open the new task sheet', () async {
        await tester.tap(find.byTooltip('New task'));
        await tester.pumpAndSettle();
        expect(find.text('Make space for a small step'), findsOneWidget);
      });

      await runStep('Fill in the task name and choose the Work category', () async {
        await tester.enterText(
          find.descendant(of: sheet, matching: find.byType(TextField)).first,
          'Stretch for five minutes',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: sheet, matching: find.text('Work')));
        await tester.pumpAndSettle();
      });

      await runStep('Save the task', () async {
        final Finder add = find.descendant(of: sheet, matching: find.text('Add task'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await settleSnackBar(tester);
        expect(find.text('Task added'), findsOneWidget);
      });

      await runStep('The task is listed with its category and time', () async {
        await dismissSnackBars(tester);
        await openTab(tester, 'Tasks');
        expect(find.text('Stretch for five minutes'), findsOneWidget);
        expect(find.text('Anytime'), findsOneWidget);
        expect(store.tasks.first.title, 'Stretch for five minutes');
        expect(store.tasks.first.category, TaskCategory.work);
      });

      await capture(tester, 'task created');
    },
  );

  registerTest(
    'Tasks',
    'Complete a task and update progress',
    description:
        'Checks a task off, verifies the open/done counters, the Done filter, '
        'and that Home removes the completed task.',
    severity: 'critical',
    tags: <String>['tasks', 'progress'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      await openTab(tester, 'Tasks');

      await runStep('Check off a task', () async {
        await tester.tap(
          find.bySemanticsLabel('Mark Finish the landing page design as done'),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Mark Finish the landing page design as not done'),
          findsOneWidget,
        );
      });

      await runStep('Open and done counters update', () async {
        expect(find.text('Open 2'), findsOneWidget);
        expect(find.text('Done 2'), findsOneWidget);
        expect(store.openTaskCount, 2);
        expect(store.tasksDoneCount, 2);
      });

      await runStep('The Done filter shows the completed task', () async {
        await tester.tap(find.text('Done 2'));
        await tester.pumpAndSettle();
        expect(find.text('Finish the landing page design'), findsOneWidget);
      });
      await capture(tester, 'task completed');

      await runStep('Home no longer shows the completed task', () async {
        await openTab(tester, 'Home');
        expect(find.text('Finish the landing page design'), findsNothing);
        expect(find.text('2 tasks waiting for you'), findsOneWidget);
      });
      await capture(tester, 'home after completion');
    },
  );

  registerTest(
    'Tasks',
    'Search and filter tasks',
    description:
        'Exercises the Done filter, the All filter and the search box, then '
        'clears the search to restore the full list.',
    severity: 'normal',
    tags: <String>['tasks', 'search'],
    body: (WidgetTester tester) async {
      await startApp(tester);
      await openTab(tester, 'Tasks');

      await runStep('Filter to completed tasks', () async {
        await tester.tap(find.text('Done 1'));
        await tester.pumpAndSettle();
        expect(find.text('Read 10 pages of Atomic Habits'), findsOneWidget);
        expect(find.text('Finish the landing page design'), findsNothing);
      });

      await runStep('Return to all tasks', () async {
        await tester.tap(find.text('All 4'));
        await tester.pumpAndSettle();
        expect(find.text('Finish the landing page design'), findsOneWidget);
      });

      await runStep('Search narrows the list', () async {
        await tester.enterText(find.byType(TextField).first, 'walk');
        await tester.pumpAndSettle();
        expect(find.text('30-minute walk in the park'), findsOneWidget);
        expect(find.text('Finish the landing page design'), findsNothing);
      });
      await capture(tester, 'search results');

      await runStep('Clear search restores all tasks', () async {
        await tester.tap(find.bySemanticsLabel('Clear search'));
        await tester.pumpAndSettle();
        expect(find.text('Finish the landing page design'), findsOneWidget);
      });
      await capture(tester, 'search cleared');
    },
  );

  registerTest(
    'Tasks',
    'Delete a task and undo it',
    description:
        'Deletes a task, checks the undo snackbar, and restores the task with '
        'the UNDO action.',
    severity: 'normal',
    tags: <String>['tasks', 'undo'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      await openTab(tester, 'Tasks');

      await runStep('Delete a task', () async {
        await tester.tap(find.byTooltip('Delete Finish the landing page design'));
        await settleSnackBar(tester);
        expect(find.text('Task deleted'), findsOneWidget);
        expect(find.text('Finish the landing page design'), findsNothing);
        expect(store.tasks.any((Task t) => t.title == 'Finish the landing page design'), isFalse);
      });

      await runStep('Undo restores the task', () async {
        await tester.tap(find.text('UNDO'));
        await tester.pumpAndSettle();
        expect(find.text('Finish the landing page design'), findsOneWidget);
        expect(store.tasks.any((Task t) => t.title == 'Finish the landing page design'), isTrue);
      });
      await capture(tester, 'task restored');
    },
  );

  // ---------------------------------------------------------- habits

  registerTest(
    'Habits',
    'Create a breaking habit',
    description:
        'Creates a break habit with a custom icon, verifies the BREAK tag, and '
        'checks that the Build/Break filters separate habits correctly.',
    severity: 'critical',
    tags: <String>['crud', 'habits'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      await openTab(tester, 'Habits');
      final Finder sheet = find.byType(NewHabitSheet);

      await runStep('Open the new habit sheet', () async {
        await tester.tap(find.byTooltip('New habit'));
        await tester.pumpAndSettle();
        expect(find.text('Start something good'), findsOneWidget);
      });

      await runStep('Choose a habit to break and describe it', () async {
        await tester.tap(find.text('I want to break'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(of: sheet, matching: find.byType(TextField)).at(0),
          'No late-night scrolling',
        );
        await tester.enterText(
          find.descendant(of: sheet, matching: find.byType(TextField)).at(1),
          'Phone away by 10 PM',
        );
        await tester.pumpAndSettle();
      });

      await runStep('Pick an icon and create the habit', () async {
        await tapVisible(tester, find.bySemanticsLabel('Habit icon option 3'));
        final Finder create = find.descendant(of: sheet, matching: find.text('Create habit'));
        await tester.ensureVisible(create);
        await tester.pumpAndSettle();
        await tester.tap(create);
        await settleSnackBar(tester);
        expect(find.text('Habit created'), findsOneWidget);
      });

      await runStep('The habit appears with its details and BREAK tag', () async {
        await dismissSnackBars(tester);
        expect(find.text('No late-night scrolling'), findsOneWidget);
        expect(find.text('Phone away by 10 PM'), findsOneWidget);
        expect(find.text('BREAK'), findsWidgets);
        expect(store.habits.first.title, 'No late-night scrolling');
        expect(store.habits.first.kind, HabitKind.breaking);
      });
      await capture(tester, 'habit created');

      await runStep('Filters separate build and break habits', () async {
        await tester.tap(find.text('Break'));
        await tester.pumpAndSettle();
        expect(find.text('No late-night scrolling'), findsOneWidget);
        expect(find.text('Drink more water'), findsNothing);

        await tester.tap(find.text('Build'));
        await tester.pumpAndSettle();
        expect(find.text('Drink more water'), findsOneWidget);
        expect(find.text('No late-night scrolling'), findsNothing);

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();
      });
      await capture(tester, 'habit filters');
    },
  );

  registerTest(
    'Habits',
    'Check off a habit and keep the streak',
    description:
        'Checks a habit off today, verifies the streak and best-streak values, '
        'and confirms Home reports the higher habit count.',
    severity: 'critical',
    tags: <String>['habits', 'streak'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      await openTab(tester, 'Habits');

      await runStep('Check off the habit for today', () async {
        await tester.tap(find.bySemanticsLabel('Check off Mindful mornings'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Uncheck Mindful mornings'), findsOneWidget);
        expect(store.habitsDoneToday, 3);
      });

      await runStep('Expanded details show the updated streak', () async {
        await tester.tap(find.text('Mindful mornings'));
        await tester.pumpAndSettle();
        expect(find.text('9 day streak'), findsOneWidget);
        expect(find.text('9 best'), findsOneWidget);
      });
      await capture(tester, 'habit checked');

      await runStep('Home reflects the higher habit count', () async {
        await openTab(tester, 'Home');
        expect(find.text('3 of 4 done today'), findsOneWidget);
        expect(find.text('Mindful mornings'), findsNothing);
      });
      await capture(tester, 'home habit progress');
    },
  );

  registerTest(
    'Habits',
    'Delete a habit with undo',
    description:
        'Expands the strongest habit to inspect its streak, deletes it, and '
        'restores it from the undo snackbar.',
    severity: 'normal',
    tags: <String>['habits', 'undo'],
    body: (WidgetTester tester) async {
      await startApp(tester);
      await openTab(tester, 'Habits');

      await runStep('Expand the strongest habit', () async {
        await tester.tap(find.text('Drink more water'));
        await tester.pumpAndSettle();
        expect(find.text('12 day streak'), findsOneWidget);
        expect(find.text('12 best'), findsOneWidget);
        expect(find.text('Delete habit'), findsOneWidget);
      });
      await capture(tester, 'habit details');

      await runStep('Delete the habit', () async {
        await tapVisible(tester, find.text('Delete habit'));
        await settleSnackBar(tester);
        expect(find.text('Habit deleted'), findsOneWidget);
        expect(find.text('Drink more water'), findsNothing);
      });

      await runStep('Undo restores the habit', () async {
        await tester.tap(find.text('UNDO'));
        await tester.pumpAndSettle();
        expect(find.text('Drink more water'), findsOneWidget);
      });
      await capture(tester, 'habit restored');
    },
  );

  // --------------------------------------------------------- journal

  registerTest(
    'Journal',
    'Save a reflection with a chosen mood',
    description:
        'Writes a reflection, selects the Great mood, saves it, verifies the '
        'entry card, then deletes and restores the reflection.',
    severity: 'critical',
    tags: <String>['journal', 'mood', 'crud'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);
      await openTab(tester, 'Journal');

      await runStep('Write a reflection', () async {
        await tester.enterText(
          find.byType(TextField).first,
          'I took a quiet walk and felt lighter.',
        );
        await tester.pumpAndSettle();
      });

      await runStep('Choose a mood and save the reflection', () async {
        await tester.tap(find.bySemanticsLabel('Mood Great').first);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Save reflection'));
        await settleSnackBar(tester);
        expect(find.text('Reflection saved'), findsOneWidget);
      });

      await runStep('The reflection is stored with its mood', () async {
        await dismissSnackBars(tester);
        expect(find.text('I took a quiet walk and felt lighter.'), findsOneWidget);
        expect(find.textContaining('· GREAT'), findsOneWidget);
        expect(store.entries.length, 2);
        expect(store.moodToday, Mood.great);
      });
      await capture(tester, 'journal reflection');

      await runStep('Delete the reflection and undo it', () async {
        await tapVisible(tester, find.byTooltip('Delete reflection').first);
        await settleSnackBar(tester);
        expect(find.text('Reflection deleted'), findsOneWidget);
        expect(find.text('I took a quiet walk and felt lighter.'), findsNothing);

        await tester.tap(find.text('UNDO'));
        await tester.pumpAndSettle();
        expect(find.text('I took a quiet walk and felt lighter.'), findsOneWidget);
      });
      await capture(tester, 'reflection restored');
    },
  );

  // --------------------------------------------------------- insights

  registerTest(
    'Insights',
    'Insights summarize activity and mood',
    description:
        'Verifies the 14-day totals, the strongest habit card derived from '
        'streak history, the activity chart and the mood breakdown.',
    severity: 'normal',
    tags: <String>['insights'],
    body: (WidgetTester tester) async {
      await startApp(tester);
      await openTab(tester, 'Insights');

      await runStep('The summary header and totals are visible', () async {
        expect(find.text('Insights'), findsWidgets);
        expect(find.text('Your last two weeks, at a glance.'), findsOneWidget);
        expect(find.text('Total check-ins'), findsOneWidget);
        expect(find.text('Tasks completed'), findsOneWidget);
        expect(find.text('Reflections kept'), findsOneWidget);
      });

      await runStep('The strongest habit is derived from streak history', () async {
        expect(find.text('YOUR STRONGEST HABIT'), findsOneWidget);
        expect(find.text('Drink more water'), findsOneWidget);
        expect(find.textContaining('12 days in a row'), findsOneWidget);
      });

      await runStep('The activity chart and mood breakdown are visible', () async {
        expect(find.text('Every small step counts'), findsOneWidget);
        expect(find.text('Daily activity, last 14 days'), findsOneWidget);
        expect(find.text('Mood over time'), findsOneWidget);
        expect(find.text('bloom with intention'), findsOneWidget);
      });
      await capture(tester, 'insights overview');
    },
  );

  // ------------------------------------------------- profile & options

  registerTest(
    'Profile & preferences',
    'Profile shows stats and the dark theme applies',
    description:
        'Opens the profile sheet, verifies the user stats, switches to the dark '
        'theme and checks that the dashboard renders in dark mode.',
    severity: 'normal',
    tags: <String>['profile', 'theme'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);

      await runStep('Open the profile sheet', () async {
        await tester.tap(find.bySemanticsLabel('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Add your name'), findsOneWidget);
        expect(find.text('Your growth journey'), findsOneWidget);
        expect(find.text('Tasks done'), findsOneWidget);
        expect(find.text('Habits today'), findsOneWidget);
        expect(find.text('Reflections'), findsOneWidget);
      });
      await capture(tester, 'profile light');

      await runStep('Switch to the dark theme', () async {
        await tapVisible(tester, find.byType(BloomSwitch));
        expect(store.dark, isTrue);
      });
      await capture(tester, 'profile dark');

      await runStep('The dark theme reaches the dashboard', () async {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('A LITTLE BETTER, EVERY DAY'), findsOneWidget);
      });
      await capture(tester, 'home dark');
    },
  );

  registerTest(
    'Profile & preferences',
    'Load sample data loads the demo content',
    description:
        'Starts with an empty store, opens Profile, explicitly loads the sample '
        'content and verifies the demo tasks and habits appear.',
    severity: 'minor',
    tags: <String>['profile', 'sample-data'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester, store: storeWith());

      await runStep('Open the sample-data confirmation', () async {
        await tester.tap(find.bySemanticsLabel('Profile'));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Load sample data'));
        expect(find.text('Replace everything'), findsOneWidget);
      });

      await runStep('Confirm loading the sample content', () async {
        await tapVisible(tester, find.text('Replace everything'));
        await settleSnackBar(tester);
        expect(find.text('Sample data loaded'), findsOneWidget);
        expect(store.tasks.length, 4);
        expect(store.habits.length, 4);
        expect(store.entries.length, 1);
      });
      await capture(tester, 'sample data loaded');
    },
  );

  registerTest(
    'Profile & preferences',
    'Notifications summarize the day',
    description:
        'Opens the notification sheet and verifies its task, streak and habit '
        'summaries, then closes it with Got it.',
    severity: 'normal',
    tags: <String>['notifications'],
    body: (WidgetTester tester) async {
      await startApp(tester);

      await runStep('Open notifications', () async {
        await tester.tap(find.bySemanticsLabel('Notifications'));
        await tester.pumpAndSettle();
        expect(find.textContaining('right on track'), findsOneWidget);
        expect(find.text('3 tasks waiting'), findsOneWidget);
        expect(find.text('12-day streak alive'), findsOneWidget);
        expect(find.text('2 habits left today'), findsOneWidget);
      });
      await capture(tester, 'daily summary');

      await runStep('Close the sheet', () async {
        await tapVisible(tester, find.text('Got it'));
        expect(find.text('Got it'), findsNothing);
      });
    },
  );

  // ---------------------------------------------------- home behaviour

  registerTest(
    'Home dashboard',
    'Completing a task advances the focus list',
    description:
        'Seeds four open tasks, completes the first one on Home and verifies '
        'that the fourth task moves into the focus list.',
    severity: 'critical',
    tags: <String>['home', 'tasks'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(
        tester,
        store: storeWith(
          tasks: <Task>[
            sampleTask('t1', 'Task one'),
            sampleTask('t2', 'Task two'),
            sampleTask('t3', 'Task three'),
            sampleTask('t4', 'Task four'),
          ],
        ),
      );

      await runStep('Home shows the first three open tasks', () async {
        expect(find.text('Task one'), findsOneWidget);
        expect(find.text('Task two'), findsOneWidget);
        expect(find.text('Task three'), findsOneWidget);
        expect(find.text('Task four'), findsNothing);
      });

      await runStep('Completing the first task pulls the next one up', () async {
        await tester.tap(find.bySemanticsLabel('Mark Task one as done'));
        await tester.pumpAndSettle();
        expect(find.text('Task one'), findsNothing);
        expect(find.text('Task four'), findsOneWidget);
        expect(store.tasks.firstWhere((Task t) => t.id == 't1').done, isTrue);
      });
      await capture(tester, 'focus list advanced');
    },
  );

  registerTest(
    'Home dashboard',
    'Mood check-in is remembered across screens',
    description:
        'Selects the Amazing mood on Home, verifies it is saved, and checks '
        'that the Journal opens with the same mood selected.',
    severity: 'normal',
    tags: <String>['home', 'mood'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester);

      await runStep('Pick Amazing on Home', () async {
        await tapVisible(tester, find.bySemanticsLabel('Mood Amazing'));
        expect(store.moodToday, Mood.amazing);
        expect(semanticsSelected(tester, find.bySemanticsLabel('Mood Amazing')), isTrue);
      });
      await capture(tester, 'mood selected');

      await runStep('The Journal starts from the same mood', () async {
        await openTab(tester, 'Journal');
        await tester.ensureVisible(find.text("What's on your mind today?"));
        await tester.pumpAndSettle();
        expect(semanticsSelected(tester, find.bySemanticsLabel('Mood Amazing')), isTrue);
      });
      await capture(tester, 'journal mood prefilled');
    },
  );

  registerTest(
    'Home dashboard',
    'Empty states celebrate a finished day',
    description:
        'Loads a store where every task and habit is already complete and '
        'verifies both celebration empty states on Home.',
    severity: 'minor',
    tags: <String>['home', 'empty-state'],
    body: (WidgetTester tester) async {
      await startApp(
        tester,
        store: storeWith(
          tasks: <Task>[sampleTask('t1', 'Only task', done: true)],
          habits: <Habit>[sampleHabit('h1', 'Only habit', doneToday: true)],
        ),
      );

      await runStep('Home reports that every task is complete', () async {
        expect(find.text('All caught up'), findsOneWidget);
        expect(find.text('Every task is done. Enjoy the space.'), findsOneWidget);
      });

      await runStep('Home reports that every habit is complete', () async {
        expect(find.text('All done for today'), findsOneWidget);
        expect(find.text('Every habit is checked off. Nicely done.'), findsOneWidget);
      });
      await capture(tester, 'all caught up');
    },
  );

  registerTest(
    'First run',
    'Fresh install starts with a welcoming empty state',
    description:
        'Confirms a new install has no demo persona or sample content, shows the '
        'new gold logo and first actions, and keeps the profile generic.',
    severity: 'critical',
    tags: <String>['onboarding', 'empty-state', 'first-run'],
    body: (WidgetTester tester) async {
      final BloomStore store = await startApp(tester, store: storeWith());

      await runStep('The new install contains no sample data or demo persona', () async {
        expect(store.tasks, isEmpty);
        expect(store.habits, isEmpty);
        expect(store.entries, isEmpty);
        expect(find.text('Alex Morgan'), findsNothing);
        expect(find.text('Drink more water'), findsNothing);
        expect(find.text('Finish the landing page design'), findsNothing);
      });

      await runStep('The welcome state shows the gold logo and first actions', () async {
        expect(find.text('Welcome to bloom.'), findsOneWidget);
        expect(find.bySemanticsLabel('bloom welcome logo'), findsOneWidget);
        expect(find.text('Add your first task'), findsOneWidget);
        expect(find.text('Create a habit'), findsOneWidget);
        expect(find.text('Three small ways to start'), findsOneWidget);
      });
      await capture(tester, 'welcome empty state');

      await runStep('The task action opens the task sheet', () async {
        await tester.tap(find.text('Add your first task'));
        await tester.pumpAndSettle();
        expect(find.text('Make space for a small step'), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      });

      await runStep('The habit action opens the habit sheet', () async {
        await tester.tap(find.text('Create a habit'));
        await tester.pumpAndSettle();
        expect(find.text('Start something good'), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      });

      await runStep('The profile is generic, not a demo persona', () async {
        await tester.tap(find.bySemanticsLabel('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Add your name'), findsOneWidget);
        expect(find.text('Alex Morgan'), findsNothing);
      });
      await capture(tester, 'first run profile');
    },
  );
}
