import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

Future<void> showBloomSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim,
    builder: (sheetContext) => _SheetShell(child: child),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sized against the sheet's own box, which inside the device frame is
        // the phone height rather than the window height.
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available * 0.92),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  10,
                  22,
                  26 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: scheme.outline,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SheetHeading extends StatelessWidget {
  const SheetHeading({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BloomText.display(21, FontWeight.w800, letterSpacing: -0.6)),
        const SizedBox(height: 5),
        Text(
          body,
          style: BloomText.body(12.5, FontWeight.w400, height: 1.6, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: BloomText.body(
        11,
        FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class SheetTextField extends StatelessWidget {
  const SheetTextField({
    super.key,
    required this.controller,
    this.hint,
    this.autofocus = false,
    this.onChanged,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: scheme.outline, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        maxLength: maxLength,
        style: BloomText.body(15, FontWeight.w400),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: BloomText.body(
            15,
            FontWeight.w400,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------- new task

class NewTaskSheet extends StatefulWidget {
  const NewTaskSheet({super.key});

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  final _title = TextEditingController();
  TaskCategory _category = TaskCategory.personal;
  TimeOfDay? _time;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final time = _time;
    final canSave = _title.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading(
          title: 'Make space for a small step',
          body: 'What would you like to focus on?',
        ),
        const _FieldLabel('Task name'),
        SheetTextField(
          controller: _title,
          autofocus: true,
          maxLength: 80,
          hint: 'e.g. Make time for a walk',
          onChanged: (_) => setState(() {}),
        ),
        const _FieldLabel('Category'),
        Row(
          children: [
            for (final category in TaskCategory.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _category = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: category == _category ? scheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CategoryChip(category),
                  ),
                ),
              ),
          ],
        ),
        const _FieldLabel('Time (optional)'),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(BloomIcon.clock.data, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  time == null ? 'Anytime' : time.format(context),
                  style: BloomText.body(
                    15,
                    FontWeight.w400,
                    color: time == null ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Add task',
          icon: BloomIcon.plus,
          enabled: canSave,
          onTap: () {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            store.addTask(
              title: _title.text,
              category: _category,
              time: time == null ? 'Anytime' : time.format(context),
            );
            navigator.pop();
            showBloomSnackBarOn(messenger, 'Task added');
          },
        ),
      ],
    );
  }
}

/// --------------------------------------------------------------- new habit

class NewHabitSheet extends StatefulWidget {
  const NewHabitSheet({super.key});

  @override
  State<NewHabitSheet> createState() => _NewHabitSheetState();
}

class _NewHabitSheetState extends State<NewHabitSheet> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  HabitKind _kind = HabitKind.build;
  int _preset = 0;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canSave = _title.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading(
          title: 'Start something good',
          body: 'Choose a habit to build — or one to leave behind.',
        ),
        const _FieldLabel(''),
        Row(
          children: [
            for (final kind in HabitKind.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kind = kind),
                  child: Container(
                    height: 46,
                    margin: EdgeInsets.only(right: kind == HabitKind.values.last ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kind == _kind ? scheme.secondaryContainer : null,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: kind == _kind ? Colors.transparent : scheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      kind.choice,
                      style: BloomText.body(
                        12.5,
                        FontWeight.w700,
                        color: kind == _kind
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const _FieldLabel('Habit name'),
        SheetTextField(
          controller: _title,
          autofocus: true,
          maxLength: 60,
          hint: 'e.g. Read every morning',
          onChanged: (_) => setState(() {}),
        ),
        const _FieldLabel('What does success look like?'),
        SheetTextField(
          controller: _subtitle,
          maxLength: 80,
          hint: 'e.g. 10 pages before breakfast',
        ),
        const _FieldLabel('Icon & color'),
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                for (var col = 0; col < 4; col++)
                  Expanded(
                    child: _PresetButton(
                      index: row * 4 + col,
                      chosen: _preset == row * 4 + col,
                      onTap: () => setState(() => _preset = row * 4 + col),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Create habit',
          icon: BloomIcon.plus,
          enabled: canSave,
          onTap: () {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final (icon, tone) = habitPresets[_preset];
            final fallback = _kind == HabitKind.build
                ? 'A little better, every day'
                : 'Make space for better things';
            store.addHabit(
              title: _title.text,
              subtitle: _subtitle.text.trim().isEmpty ? fallback : _subtitle.text,
              icon: icon,
              tone: tone,
              kind: _kind,
            );
            navigator.pop();
            showBloomSnackBarOn(messenger, 'Habit created');
          },
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.index, required this.chosen, required this.onTap});

  final int index;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, tone) = habitPresets[index];

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: chosen,
        label: 'Habit icon option ${index + 1}',
        container: true,
        excludeSemantics: true,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: chosen ? scheme.primary : Colors.transparent,
                width: 2,
              ),
              color: chosen ? scheme.primary.withValues(alpha: 0.08) : null,
            ),
            child: IconTile(icon: icon, tone: tone, size: 46, radius: 15, iconSize: 20),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------- notifications

class NotifsSheet extends StatelessWidget {
  const NotifsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final today = dateKey();

    final openTasks = store.openTaskCount;
    final habitsLeft = store.habits.where((h) => !h.history.contains(today)).length;
    final ranked = [...store.habits]..sort((a, b) => streakOf(b).compareTo(streakOf(a)));
    final topHabit = ranked.isEmpty ? null : ranked.first;

    final notes = <(BloomIcon, String, String)>[
      if (openTasks > 0)
        (
          BloomIcon.check,
          '$openTasks task${openTasks > 1 ? 's' : ''} waiting',
          'One thing at a time. Pick the one that matters most.',
        ),
      if (topHabit != null)
        (
          BloomIcon.fire,
          '${streakOf(topHabit)}-day streak alive',
          '“${topHabit.title}” is your strongest habit right now.',
        ),
      if (habitsLeft > 0)
        (
          BloomIcon.leaf,
          '$habitsLeft habit${habitsLeft > 1 ? 's' : ''} left today',
          'Little things make a big difference.',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading(title: 'You’re right on track', body: ''),
        const SizedBox(height: 4),
        Text(
          formatDateLong(DateTime.now()),
          style: BloomText.body(12.5, FontWeight.w400, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        for (final (icon, title, body) in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(
                    icon: icon,
                    tone: HabitTone.green,
                    size: 38,
                    radius: 12,
                    iconSize: 19,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: BloomText.body(13, FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          body,
                          style: BloomText.body(
                            11.5,
                            FontWeight.w400,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Got it', onTap: () => Navigator.of(context).pop()),
      ],
    );
  }
}

/// ----------------------------------------------------------------- profile

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  bool _confirmReset = false;

  Future<void> _editName(BuildContext context, BloomStore store) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NameDialog(initialName: store.name),
    );
    if (result != null) store.setName(result);
  }

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final String displayName = store.name.trim();
    final String initial = initialOf(displayName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Profile', style: BloomText.display(21, FontWeight.w800, letterSpacing: -0.6)),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: initial.isEmpty
                  ? Icon(
                      Icons.person_outline,
                      size: 30,
                      color: scheme.onPrimaryContainer,
                    )
                  : Text(
                      initial,
                      style: BloomText.body(
                        24,
                        FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: displayName.isEmpty ? 'Add your name' : 'Edit your name',
                    child: InkWell(
                      onTap: () => _editName(context, store),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName.isEmpty ? 'Add your name' : displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: displayName.isEmpty
                                    ? BloomText.display(15, FontWeight.w700, color: scheme.primary)
                                    : BloomText.display(17, FontWeight.w800, letterSpacing: -0.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(BloomIcon.pencil.data, size: 15, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your growth journey',
                    style: BloomText.body(11.5, FontWeight.w400, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _ProfileStat(value: '${store.tasksDoneCount}', label: 'Tasks done'),
            const SizedBox(width: 10),
            _ProfileStat(value: '${store.habitsDoneToday}', label: 'Habits today'),
            const SizedBox(width: 10),
            _ProfileStat(value: '${store.entries.length}', label: 'Reflections'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              IconTile(
                icon: store.dark ? BloomIcon.moon : BloomIcon.sun,
                tone: HabitTone.lilac,
                size: 42,
                iconSize: 19,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark theme', style: BloomText.body(13.5, FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Follows Material You tones',
                      style: BloomText.body(
                        11,
                        FontWeight.w400,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              BloomSwitch(value: store.dark, onChanged: store.setDark),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_confirmReset)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This replaces everything with the sample content. Your tasks, habits and reflections can't be recovered.",
                  style: BloomText.body(12, FontWeight.w500, height: 1.55),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextBtn(
                      label: 'Cancel',
                      icon: null,
                      onTap: () => setState(() => _confirmReset = false),
                    ),
                    TextBtn(
                      label: 'Replace everything',
                      icon: BloomIcon.spark,
                      danger: true,
                      onTap: () {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        store.resetToSample();
                        navigator.pop();
                        showBloomSnackBarOn(messenger, 'Sample data loaded');
                      },
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          TextBtn(
            label: 'Load sample data',
            icon: BloomIcon.spark,
            expand: true,
            onTap: () => setState(() => _confirmReset = true),
          ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initialName});

  final String initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.initialName.trim().isEmpty;
    return AlertDialog(
      title: Text(isNew ? 'Add your name' : 'Edit your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: 'Your name',
          counterText: '',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(value, style: BloomText.display(19, FontWeight.w800, color: scheme.primary)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: BloomText.body(
                10,
                FontWeight.w700,
                letterSpacing: 0.3,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
