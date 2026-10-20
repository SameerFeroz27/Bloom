import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mood_face.dart';
import '../widgets/progress_ring.dart';
import '../widgets/rows.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onNewTask,
    required this.onNewHabit,
  });

  final ValueChanged<BloomTab> onOpenTab;
  final VoidCallback onNewTask;
  final VoidCallback onNewHabit;

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);

    // A brand-new install gets a deliberate welcome screen instead of a
    // dashboard full of zeroes.
    if (store.tasks.isEmpty && store.habits.isEmpty && store.entries.isEmpty) {
      return _FirstRunView(
        onNewTask: onNewTask,
        onNewHabit: onNewHabit,
        onOpenJournal: () => onOpenTab(BloomTab.journal),
      );
    }

    final today = dateKey();

    final tasksTotal = store.tasks.length;
    final tasksDone = store.tasksDoneCount;
    final taskPct = tasksTotal == 0 ? 0.0 : tasksDone / tasksTotal * 100;

    final habitsTotal = store.habits.length;
    final habitsDone = store.habitsDoneToday;
    final habitPct = habitsTotal == 0 ? 0.0 : habitsDone / habitsTotal * 100;

    final topStreak = store.habits.fold<int>(0, (best, h) => math.max(best, streakOf(h)));

    final week = currentWeek();
    final weekActivity = [
      for (final d in week)
        store.tasks.where((t) => t.done && (t.doneOn ?? '') == dateKey(d)).length +
            store.habits.where((h) => h.history.contains(dateKey(d))).length,
    ];
    final maxActivity = weekActivity.fold<int>(1, (m, v) => math.max(m, v));

    // Finished items drop off the home lists, so the next one moves up.
    final focusTasks = store.tasks.where((t) => !t.done).take(3).toList();
    final topHabits = store.habits
        .where((h) => !h.history.contains(today))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _hero(context, taskPct, tasksDone, tasksTotal, habitPct, habitsDone, topStreak),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHead(
                title: "Today's focus",
                subtitle: store.openTaskCount == 0
                    ? 'Nothing waiting right now'
                    : '${store.openTaskCount} tasks waiting for you',
                trailing: TextBtn(label: 'View all', onTap: () => onOpenTab(BloomTab.tasks)),
              ),
              const SizedBox(height: 6),
              if (focusTasks.isEmpty)
                EmptyState(
                  icon: BloomIcon.check,
                  title: store.tasks.isEmpty ? 'Nothing on your plate' : 'All caught up',
                  body: store.tasks.isEmpty
                      ? 'Add your first task and take it one step at a time.'
                      : 'Every task is done. Enjoy the space.',
                )
              else
                bloomRows(context, [
                  for (final t in focusTasks)
                    RemovableRow(
                      key: ValueKey('task-${t.id}'),
                      onRemoved: () => store.toggleTask(t.id),
                      builder: (context, leave) => TaskRow(task: t, onToggle: leave),
                    ),
                ]),
            ],
          ),
        ),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHead(
                title: 'Your daily habits',
                subtitle: '$habitsDone of $habitsTotal done today',
                trailing: TextBtn(label: 'View all', onTap: () => onOpenTab(BloomTab.habits)),
              ),
              const SizedBox(height: 6),
              if (topHabits.isEmpty)
                EmptyState(
                  icon: BloomIcon.leaf,
                  title: store.habits.isEmpty ? 'No habits yet' : 'All done for today',
                  body: store.habits.isEmpty
                      ? 'Create a habit you want to build — or one to break.'
                      : 'Every habit is checked off. Nicely done.',
                )
              else
                bloomRows(context, [
                  for (final h in topHabits)
                    RemovableRow(
                      key: ValueKey('habit-${h.id}'),
                      onRemoved: () => store.toggleHabitToday(h.id),
                      builder: (context, leave) => _HomeHabitRow(habit: h, onToggle: leave),
                    ),
                ]),
            ],
          ),
        ),

        const _MoodCard(),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHead(
                title: 'A fresh week',
                subtitle:
                    '${formatDayShort(dateKey(week.first))} – ${formatDayShort(dateKey(week.last))}',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < week.length; i++)
                    Expanded(
                      child: _WeekCell(
                        day: week[i],
                        activity: weekActivity[i],
                        maxActivity: maxActivity,
                        isToday: dateKey(week[i]) == today,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        BannerCta(
          icon: BloomIcon.spark,
          title: 'Small steps, big change.',
          body: 'Add one thing that matters today.',
          onTap: onNewTask,
        ),
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    double taskPct,
    int tasksDone,
    int tasksTotal,
    double habitPct,
    int habitsDone,
    int topStreak,
  ) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final String displayName = store.name.trim();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        boxShadow: dark ? null : extras.shadow1,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: _Glow(size: 240, color: scheme.primaryContainer),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: _Glow(size: 220, color: scheme.secondaryContainer),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    const Eyebrow('A LITTLE BETTER, EVERY DAY'),
                    Text(
                      formatDateLong(DateTime.now()),
                      style: BloomText.body(
                        10.5,
                        FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${greeting()}${displayName.isEmpty ? '' : ', $displayName'}.\n'
                  'Make room for a better you.',
                  style: BloomText.display(24, FontWeight.w800, letterSpacing: -0.8, height: 1.3),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Two rings share the full card width on a phone, so the
                    // labels inside them never have to compete with stats.
                    final ringSize = math.min(118.0, (constraints.maxWidth - 16) / 2);
                    return Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: ProgressRing(
                              progress: taskPct,
                              value: '${taskPct.round()}%',
                              label: '$tasksDone/$tasksTotal tasks',
                              size: ringSize,
                              stroke: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Center(
                            child: ProgressRing(
                              progress: habitPct,
                              value: '$habitsDone',
                              label: 'habits',
                              size: ringSize,
                              stroke: 9,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        icon: BloomIcon.trophy,
                        value: '$topStreak days',
                        label: 'Best active streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        icon: BloomIcon.book,
                        value: '${store.entries.length}',
                        label: 'Reflections kept',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstRunView extends StatelessWidget {
  const _FirstRunView({
    required this.onNewTask,
    required this.onNewHabit,
    required this.onOpenJournal,
  });

  final VoidCallback onNewTask;
  final VoidCallback onNewHabit;
  final VoidCallback onOpenJournal;

  static const Color _gold = Color(0xFFD4B36A);
  static const Color _cream = Color(0xFFF7F1E3);
  static const Color _muted = Color(0xFFC9D6C4);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A3023), Color(0xFF1A4F35)],
            ),
            border: Border.all(color: const Color(0x4DD4B36A)),
            boxShadow: BloomExtras.of(context).shadow2,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -50,
                child: _Glow(size: 220, color: _gold.withValues(alpha: 0.18)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Semantics(
                        image: true,
                        label: 'bloom welcome logo',
                        container: true,
                        excludeSemantics: true,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _gold.withValues(alpha: 0.55), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/branding/bloom_logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome to bloom.',
                      textAlign: TextAlign.center,
                      style: BloomText.display(
                        24,
                        FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                        color: _cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A calmer way to build habits, finish tasks and reflect. '
                      'No sample data — this space starts with you.',
                      textAlign: TextAlign.center,
                      style: BloomText.body(
                        12.5,
                        FontWeight.w400,
                        height: 1.6,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _WelcomeAction(
                      label: 'Add your first task',
                      icon: BloomIcon.plus,
                      filled: true,
                      onTap: onNewTask,
                    ),
                    const SizedBox(height: 10),
                    _WelcomeAction(
                      label: 'Create a habit',
                      icon: BloomIcon.leaf,
                      filled: false,
                      onTap: onNewHabit,
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onOpenJournal,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(BloomIcon.book.data, size: 15, color: _gold),
                            const SizedBox(width: 6),
                            Text(
                              'Write your first reflection',
                              style: BloomText.body(11.5, FontWeight.w700, color: _gold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Three small ways to start',
                style: BloomText.display(16, FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick whichever feels easiest today.',
                style: BloomText.body(
                  11.5,
                  FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const _WelcomeStep(
                icon: BloomIcon.check,
                tone: HabitTone.green,
                title: 'Capture what matters',
                body: 'Add a task and tick it off when it is done.',
              ),
              const SizedBox(height: 12),
              const _WelcomeStep(
                icon: BloomIcon.leaf,
                tone: HabitTone.green,
                title: 'Build a habit',
                body: 'Check in daily and watch your streak grow.',
              ),
              const SizedBox(height: 12),
              const _WelcomeStep(
                icon: BloomIcon.book,
                tone: HabitTone.sand,
                title: 'Reflect',
                body: 'A short journal entry keeps the week clear.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeAction extends StatelessWidget {
  const _WelcomeAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final BloomIcon icon;
  final bool filled;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFD4B36A);
  static const Color _deep = Color(0xFF0A3023);

  @override
  Widget build(BuildContext context) {
    final Color foreground = filled ? _deep : _gold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? _gold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(color: _gold.withValues(alpha: 0.65), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon.data, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: BloomText.body(13, FontWeight.w700, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final BloomIcon icon;
  final HabitTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon, tone: tone, size: 38, radius: 12, iconSize: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BloomText.body(12.5, FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                body,
                style: BloomText.body(
                  11,
                  FontWeight.w400,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value, required this.label});

  final BloomIcon icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon.data, size: 17, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BloomText.display(14, FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BloomText.body(
                    9.5,
                    FontWeight.w500,
                    height: 1.25,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHabitRow extends StatelessWidget {
  const _HomeHabitRow({required this.habit, required this.onToggle});

  final Habit habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          HabitIconView(habit: habit),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title, style: BloomText.body(13.5, FontWeight.w600, letterSpacing: -0.1)),
                const SizedBox(height: 3),
                Text(
                  habit.subtitle,
                  style: BloomText.body(11, FontWeight.w400, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StreakBadge(habit: habit),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onToggle,
            child: Semantics(
              button: true,
              label: 'Check off ${habit.title}',
              container: true,
              excludeSemantics: true,
              onTap: onToggle,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 18, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final current = store.moodToday ?? Mood.good;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: BloomText.display(16, FontWeight.w700, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A quick daily check-in',
                      style: BloomText.body(11.5, FontWeight.w400, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              MoodFace(mood: current, size: 36, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final mood in Mood.values)
                Expanded(
                  child: _MoodButton(
                    mood: mood,
                    chosen: mood == current,
                    onTap: () => store.setMoodToday(mood),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.mood, required this.chosen, required this.onTap});

  final Mood mood;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = chosen ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: chosen,
        label: 'Mood ${mood.label}',
        container: true,
        excludeSemantics: true,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: chosen ? 1 : 0.65,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            decoration: BoxDecoration(
              color: chosen ? scheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                MoodFace(mood: mood, size: 30, color: tint),
                const SizedBox(height: 7),
                Text(mood.label, style: BloomText.body(9.5, FontWeight.w700, color: tint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    required this.day,
    required this.activity,
    required this.maxActivity,
    required this.isToday,
  });

  final DateTime day;
  final int activity;
  final int maxActivity;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = activity == 0 ? 0.0 : math.max(8.0, activity / maxActivity * 44);

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: 14,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary, scheme.primaryContainer],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weekdayNarrow(day),
          style: BloomText.body(9.5, FontWeight.w600, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isToday ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${day.day}',
            style: BloomText.display(
              13,
              FontWeight.w700,
              color: isToday ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
