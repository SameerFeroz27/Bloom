import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/rows.dart';

enum _HabitFilter { all, build, breaking }

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, required this.onNewHabit});

  final VoidCallback onNewHabit;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  _HabitFilter _filter = _HabitFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final today = dateKey();

    final visible = store.habits.where((h) {
      if (_filter == _HabitFilter.build) return h.kind == HabitKind.build;
      if (_filter == _HabitFilter.breaking) return h.kind == HabitKind.breaking;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        PageHead(
          eyebrow: 'SMALL HABITS, LASTING CHANGE',
          title: 'Habits',
          subtitle: '${store.habitsDoneToday} of ${store.habits.length} done today',
        ),

        SegmentedTabs<_HabitFilter>(
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
          options: const [
            (_HabitFilter.all, 'All'),
            (_HabitFilter.build, 'Build'),
            (_HabitFilter.breaking, 'Break'),
          ],
        ),

        if (visible.isEmpty)
          const EmptyState(
            icon: BloomIcon.leaf,
            title: 'No habits yet',
            body: 'Create a habit you want to build — or one you want to break.',
          )
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: bloomRows(context, [
              for (final h in visible) _HabitRow(habit: h, done: h.history.contains(today)),
            ]),
          ),

        BannerCta(
          icon: BloomIcon.leaf,
          title: 'New habit',
          body: 'Start something good today.',
          onTap: widget.onNewHabit,
        ),
      ],
    );
  }
}

class _HabitRow extends StatefulWidget {
  const _HabitRow({required this.habit, required this.done});

  final Habit habit;
  final bool done;

  @override
  State<_HabitRow> createState() => _HabitRowState();
}

class _HabitRowState extends State<_HabitRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final habit = widget.habit;
    final done = widget.done;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HabitIconView(habit: habit, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              habit.title,
                              style: BloomText.body(
                                13.5,
                                FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (habit.kind == HabitKind.breaking) ...[
                            const SizedBox(width: 7),
                            const _BreakTag(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        habit.subtitle,
                        style: BloomText.body(
                          11,
                          FontWeight.w400,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StreakBadge(habit: habit),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => store.toggleHabitToday(habit.id),
                child: Semantics(
                  button: true,
                  toggled: done,
                  label: done ? 'Uncheck ${habit.title}' : 'Check off ${habit.title}',
                  container: true,
                  excludeSemantics: true,
                  onTap: () => store.toggleHabitToday(habit.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: done ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: done ? scheme.primary : scheme.outline,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.add,
                      size: 19,
                      color: done ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                _DetailStat(
                  icon: BloomIcon.fire,
                  label: '${streakOf(habit)} day streak',
                ),
                const SizedBox(width: 14),
                _DetailStat(
                  icon: BloomIcon.trophy,
                  label: '${bestStreakOf(habit)} best',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _HistoryDots(history: habit.history),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextBtn(
                label: 'Delete habit',
                icon: BloomIcon.trash,
                danger: true,
                onTap: () {
                  final removed = store.deleteHabit(habit.id);
                  if (removed != null) {
                    showUndoSnackBar(
                      context,
                      'Habit deleted',
                      () => store.restoreHabit(removed),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakTag extends StatelessWidget {
  const _BreakTag();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'BREAK',
        style: BloomText.body(
          7.5,
          FontWeight.w700,
          letterSpacing: 0.8,
          color: scheme.error,
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.icon, required this.label});

  final BloomIcon icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon.data, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          label,
          style: BloomText.body(11, FontWeight.w600, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The last seven days as filled or empty dots.
class _HistoryDots extends StatelessWidget {
  const _HistoryDots({required this.history});

  final List<String> history;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = history.toSet();
    final days = lastNDays(7);

    return Row(
      children: [
        for (final key in days)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: done.contains(key) ? scheme.primary : scheme.surfaceContainerHigh,
              border: Border.all(
                color: done.contains(key) ? scheme.primary : scheme.outline,
                width: 1.5,
              ),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
