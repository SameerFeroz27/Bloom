import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mood_face.dart';
import '../widgets/progress_ring.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final days = lastNDays(14);
    final activity = [
      for (final key in days)
        store.tasks.where((t) => t.done && (t.doneOn ?? '') == key).length +
            store.habits.where((h) => h.history.contains(key)).length,
    ];
    final maxActivity = activity.fold<int>(1, (m, v) => math.max(m, v));
    final totals = activity.fold<int>(0, (sum, v) => sum + v);
    final activeDays = activity.where((v) => v > 0).length;

    final ranked = [...store.habits]..sort((a, b) => streakOf(b).compareTo(streakOf(a)));
    final bestHabit = ranked.isEmpty ? null : ranked.first;

    final dayMoods = store.moods.values.toList();
    final moodTally = [for (final m in Mood.values) (m, dayMoods.where((v) => v == m).length)];
    final maxMood = moodTally.fold<int>(1, (m, e) => math.max(m, e.$2));

    final week = currentWeek();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const PageHead(
          eyebrow: 'LOOK HOW FAR YOU’VE GROWN',
          title: 'Insights',
          subtitle: 'Your last two weeks, at a glance.',
        ),

        SectionCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ProgressRing(
                progress: activeDays / 14 * 100,
                value: '$activeDays',
                label: 'of 14 days active',
                size: 132,
                stroke: 11,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    _InsightStat(value: '$totals', label: 'Total check-ins'),
                    _InsightStat(
                      value: '${store.tasksDoneCount}',
                      label: 'Tasks completed',
                    ),
                    _InsightStat(value: '${store.entries.length}', label: 'Reflections kept'),
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
              const CardHead(
                title: 'Every small step counts',
                subtitle: 'Daily activity, last 14 days',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 7),
                          child: _BarColumn(
                            factor: activity[i] == 0
                                ? 0
                                : math.max(0.06, activity[i] / maxActivity),
                            isToday: days[i] == dateKey(),
                            label: i.isEven ? formatDayShort(days[i]).split(' ').last : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (bestHabit != null)
          SectionCard(
            child: Row(
              children: [
                HabitIconView(habit: bestHabit, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('YOUR STRONGEST HABIT'),
                      const SizedBox(height: 3),
                      Text(
                        bestHabit.title,
                        style: BloomText.display(15.5, FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            BloomIcon.fire.data,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${streakOf(bestHabit)} days in a row — keep it alive today.',
                              style: BloomText.body(
                                12,
                                FontWeight.w400,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
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
              const CardHead(
                title: 'Mood over time',
                subtitle: 'From your daily check-ins',
              ),
              const SizedBox(height: 16),
              Column(
                spacing: 11,
                children: [
                  for (final (mood, count) in moodTally)
                    Row(
                      children: [
                        MoodFace(mood: mood, size: 26, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              height: 10,
                              color: scheme.surfaceContainerHigh,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: count / maxMood,
                                child: ColoredBox(color: scheme.primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 16,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: BloomText.display(13, FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),

        SectionCard(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
          child: Column(
            children: [
              Icon(BloomIcon.spark.data, size: 26, color: scheme.primary),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'You don’t need to change everything. Just one small thing today.',
                  textAlign: TextAlign.center,
                  style: BloomText.display(15.5, FontWeight.w800, letterSpacing: -0.2, height: 1.55),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(BloomIcon.leaf.data, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 7),
                  Text(
                    'bloom with intention',
                    style: BloomText.body(10, FontWeight.w500, color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'Week of ${formatDayShort(dateKey(week.first))}',
                    style: BloomText.body(
                      9,
                      FontWeight.w500,
                      letterSpacing: 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightStat extends StatelessWidget {
  const _InsightStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 34,
          child: Text(value, style: BloomText.display(20, FontWeight.w800, color: scheme.primary)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: BloomText.body(11, FontWeight.w400, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// One column of the activity chart: a tall track with a bar growing from the
/// bottom, and an optional day label underneath.
class _BarColumn extends StatelessWidget {
  const _BarColumn({required this.factor, required this.isToday, required this.label});

  final double factor;
  final bool isToday;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final barColors = isToday
        ? (dark
              ? [const Color(0xFFE5B375), const Color(0xFF8A6234)]
              : [const Color(0xFFC9963F), const Color(0xFFE5C084)])
        : [scheme.primary, Color.lerp(scheme.primary, scheme.surface, 0.45)!];

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 18,
              height: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: factor,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: barColors,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16,
          child: label == null
              ? null
              : Center(
                  child: Text(
                    label!,
                    style: BloomText.body(
                      9,
                      FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
