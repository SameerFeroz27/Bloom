import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

/// One row of the task list, shared by Home and the Tasks screen.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.onToggle});

  final Task task;

  /// Replaces the checkbox action, so a host screen can animate the row out
  /// before the task is actually completed.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final VoidCallback toggle = onToggle ?? () => store.toggleTask(task.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: task.done
                ? 'Mark ${task.title} as not done'
                : 'Mark ${task.title} as done',
            container: true,
            excludeSemantics: true,
            onTap: toggle,
            child: GestureDetector(
              onTap: toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.done ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: task.done ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: task.done ? Icon(Icons.check, size: 15, color: scheme.onPrimary) : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: BloomText.body(
                    13.5,
                    FontWeight.w500,
                    letterSpacing: -0.1,
                    height: 1.45,
                    color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
                  ).copyWith(decoration: task.done ? TextDecoration.lineThrough : null),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    CategoryChip(task.category),
                    const SizedBox(width: 8),
                    Icon(BloomIcon.clock.data, size: 11, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.time,
                        style: BloomText.body(
                          10.5,
                          FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GhostIconButton(
            icon: BloomIcon.trash,
            tooltip: 'Delete ${task.title}',
            onTap: () {
              final removed = store.deleteTask(task.id);
              if (removed != null) {
                showUndoSnackBar(context, 'Task deleted', () => store.restoreTask(removed));
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 1px hairline between rows, matching the CSS row borders.
Widget bloomRowDivider(BuildContext context) =>
    Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant);

/// Lays rows out with a hairline between (but not around) them.
Widget bloomRows(BuildContext context, List<Widget> children) => Column(
  children: [
    for (var i = 0; i < children.length; i++) ...[
      children[i],
      if (i < children.length - 1) bloomRowDivider(context),
    ],
  ],
);

/// Fades a row out and collapses its space before the item is removed, so the
/// rows underneath slide up instead of jumping.
///
/// [builder] receives the callback the row should run on tap. [onRemoved] runs
/// once the exit animation has finished.
class RemovableRow extends StatefulWidget {
  const RemovableRow({super.key, required this.builder, required this.onRemoved});

  final Widget Function(BuildContext context, VoidCallback leave) builder;
  final VoidCallback onRemoved;

  @override
  State<RemovableRow> createState() => _RemovableRowState();
}

class _RemovableRowState extends State<RemovableRow> {
  static const Duration _collapse = Duration(milliseconds: 260);
  static const Duration _fade = Duration(milliseconds: 170);

  bool _leaving = false;

  void _leave() {
    if (_leaving) return;
    setState(() => _leaving = true);
    Future<void>.delayed(_collapse, () {
      if (!mounted) return;
      widget.onRemoved();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: _fade,
      curve: Curves.easeOut,
      child: ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.topCenter,
          heightFactor: _leaving ? 0 : 1,
          duration: _collapse,
          curve: Curves.easeOutCubic,
          child: widget.builder(context, _leave),
        ),
      ),
    );
  }
}
