import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/rows.dart';

enum _TaskFilter { all, open, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onNewTask});

  final VoidCallback onNewTask;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();

    final visible = store.tasks.where((t) {
      if (_filter == _TaskFilter.open && t.done) return false;
      if (_filter == _TaskFilter.done && !t.done) return false;
      if (query.isNotEmpty && !t.title.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    final open = store.openTaskCount;
    final done = store.tasksDoneCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        PageHead(
          eyebrow: 'ONE THING AT A TIME',
          title: 'My tasks',
          subtitle: open > 0
              ? "$open tasks left — you've got this."
              : 'All clear. Enjoy the space.',
        ),

        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(BloomIcon.search.data, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: BloomText.body(14, FontWeight.w400),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search your tasks',
                    hintStyle: BloomText.body(
                      14,
                      FontWeight.w400,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              if (_search.text.isNotEmpty)
                Semantics(
                  button: true,
                  label: 'Clear search',
                  container: true,
                  excludeSemantics: true,
                  onTap: () => setState(_search.clear),
                  child: GestureDetector(
                    onTap: () => setState(_search.clear),
                    child: Icon(BloomIcon.close.data, size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),

        SegmentedTabs<_TaskFilter>(
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
          options: [
            (_TaskFilter.all, 'All ${store.tasks.length}'),
            (_TaskFilter.open, 'Open $open'),
            (_TaskFilter.done, 'Done $done'),
          ],
        ),

        if (visible.isEmpty)
          EmptyState(
            icon: BloomIcon.check,
            title: query.isNotEmpty
                ? 'No matches'
                : store.tasks.isEmpty
                ? 'No tasks yet'
                : 'Nothing in this view',
            body: query.isNotEmpty
                ? 'No tasks match “$query”.'
                : store.tasks.isEmpty
                ? 'Add your first task and take it one step at a time.'
                : 'Try another filter, or add a new task below.',
          )
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: bloomRows(context, [for (final t in visible) TaskRow(task: t)]),
          ),

        BannerCta(
          icon: BloomIcon.plus,
          title: 'Add a task',
          body: 'What deserves your attention?',
          onTap: widget.onNewTask,
          trailing: BloomIcon.chevron,
        ),
      ],
    );
  }
}
