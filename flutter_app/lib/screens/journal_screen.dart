import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mood_face.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _text = TextEditingController();
  Mood _mood = Mood.good;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      _seeded = true;
      _mood = BloomScope.of(context).moodToday ?? Mood.good;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (_text.text.trim().isEmpty) return;
    final store = BloomScope.of(context);
    store.addEntry(text: _text.text, mood: _mood);
    _text.clear();
    setState(() {});
    showBloomSnackBar(context, 'Reflection saved');
  }

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canSave = _text.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const PageHead(
          eyebrow: 'A SPACE TO BE YOURSELF',
          title: 'Journal',
          subtitle: 'A clearer mind starts with a little reflection.',
        ),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's on your mind today?",
                style: BloomText.display(17, FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline, width: 1.5),
                ),
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _text,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  minLines: 4,
                  style: BloomText.body(14, FontWeight.w400, height: 1.65),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Let your thoughts flow…',
                    hintStyle: BloomText.body(
                      14,
                      FontWeight.w400,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final mood in Mood.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _MiniMood(
                        mood: mood,
                        chosen: mood == _mood,
                        onTap: () => setState(() => _mood = mood),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save reflection',
                      enabled: canSave,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (store.entries.isEmpty)
          const EmptyState(
            icon: BloomIcon.book,
            title: 'Your story starts here',
            body: 'Write your first reflection above.',
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [for (final e in store.entries) _EntryCard(entry: e)],
          ),
      ],
    );
  }
}

class _MiniMood extends StatelessWidget {
  const _MiniMood({required this.mood, required this.chosen, required this.onTap});

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
          opacity: chosen ? 1 : 0.6,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: chosen ? scheme.secondaryContainer : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(child: MoodFace(mood: mood, size: 23, color: tint)),
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final store = BloomScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Eyebrow('${formatDayShort(entry.date).toUpperCase()} · ${entry.mood.label.toUpperCase()}'),
              ),
              GhostIconButton(
                icon: BloomIcon.trash,
                tooltip: 'Delete reflection',
                onTap: () {
                  final removed = store.deleteEntry(entry.id);
                  if (removed != null) {
                    showUndoSnackBar(
                      context,
                      'Reflection deleted',
                      () => store.restoreEntry(removed),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.text, style: BloomText.body(13, FontWeight.w400, height: 1.7)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: MoodFace(mood: entry.mood, size: 22, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
