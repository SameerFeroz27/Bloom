import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` key used everywhere a day is identified.
String dateKey([DateTime? when]) {
  final d = when ?? DateTime.now();
  return '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';
}

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

List<String> lastNDays(int n) {
  final today = DateTime.now();
  return List.generate(n, (i) => dateKey(addDays(today, -(n - 1 - i))));
}

/// Monday-start week containing today.
List<DateTime> currentWeek() {
  final now = DateTime.now();
  final offset = (now.weekday - DateTime.monday) % 7;
  final monday = addDays(now, -offset);
  return List.generate(7, (i) => addDays(monday, i));
}

/// Current run of consecutive days. Today counts as optional so a day that has
/// not been checked off yet does not break the streak.
int streakOf(Habit habit) {
  final done = habit.history.toSet();
  var streak = 0;
  var cursor = DateTime.now();
  if (!done.contains(dateKey(cursor))) cursor = addDays(cursor, -1);
  while (done.contains(dateKey(cursor))) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

int bestStreakOf(Habit habit) {
  final days = [...habit.history]..sort();
  var best = 0;
  var run = 0;
  String? prev;
  for (final key in days) {
    if (prev != null && dateKey(addDays(DateTime.parse(prev), 1)) == key) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    prev = key;
  }
  return best;
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Good evening';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  if (h < 22) return 'Good evening';
  return 'Good night';
}

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "Wednesday, October 14"
String formatDateLong(DateTime d) =>
    '${_weekdayNames[d.weekday - 1]}, ${_monthNames[d.month - 1]} ${d.day}';

/// "Oct 14"
String formatDayShort(String key) {
  final d = DateTime.parse(key);
  return '${_monthNames[d.month - 1].substring(0, 3)} ${d.day}';
}

/// Single letter day header, Monday first.
String weekdayNarrow(DateTime d) => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

String _uid() {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return '$stamp-${Random().nextInt(1 << 30).toRadixString(36)}';
}

/// The eight icon/colour pairs offered when creating a habit.
const List<(BloomIcon, HabitTone)> habitPresets = [
  (BloomIcon.water, HabitTone.sky),
  (BloomIcon.sun, HabitTone.peach),
  (BloomIcon.moon, HabitTone.lilac),
  (BloomIcon.run, HabitTone.rose),
  (BloomIcon.leaf, HabitTone.green),
  (BloomIcon.heart, HabitTone.rose),
  (BloomIcon.wind, HabitTone.sky),
  (BloomIcon.book, HabitTone.sand),
];

class BloomStore extends ChangeNotifier {
  BloomStore(this._data);

  static const storageKey = 'bloom.store.v1';

  final StoreData _data;

  List<Task> get tasks => List.unmodifiable(_data.tasks);
  List<Habit> get habits => List.unmodifiable(_data.habits);
  List<Entry> get entries => List.unmodifiable(_data.entries);
  Map<String, Mood> get moods => Map.unmodifiable(_data.moods);
  bool get dark => _data.dark;
  String get name => _data.name;

  Mood? get moodToday => _data.moods[dateKey()];

  int get openTaskCount => _data.tasks.where((t) => !t.done).length;
  int get tasksDoneCount => _data.tasks.where((t) => t.done).length;
  int get habitsDoneToday => _data.habits.where((h) => h.history.contains(dateKey())).length;

  // ---------------------------------------------------------------- tasks

  void addTask({required String title, required TaskCategory category, required String time}) {
    _data.tasks.insert(
      0,
      Task(id: _uid(), title: title.trim(), category: category, time: time),
    );
    _commit();
  }

  void toggleTask(String id) {
    final i = _data.tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final t = _data.tasks[i];
    final done = !t.done;
    _data.tasks[i] = Task(
      id: t.id,
      title: t.title,
      category: t.category,
      time: t.time,
      done: done,
      doneOn: done ? dateKey() : null,
    );
    _commit();
  }

  Task? deleteTask(String id) {
    final i = _data.tasks.indexWhere((t) => t.id == id);
    if (i == -1) return null;
    final removed = _data.tasks.removeAt(i);
    _commit();
    return removed;
  }

  void restoreTask(Task task) {
    _data.tasks.insert(0, task);
    _commit();
  }

  // --------------------------------------------------------------- habits

  void addHabit({
    required String title,
    required String subtitle,
    required BloomIcon icon,
    required HabitTone tone,
    required HabitKind kind,
  }) {
    _data.habits.insert(
      0,
      Habit(
        id: _uid(),
        title: title.trim(),
        subtitle: subtitle.trim(),
        icon: icon,
        tone: tone,
        kind: kind,
        history: const [],
      ),
    );
    _commit();
  }

  void toggleHabitToday(String id) {
    final i = _data.habits.indexWhere((h) => h.id == id);
    if (i == -1) return;
    final h = _data.habits[i];
    final today = dateKey();
    final history = [...h.history];
    if (history.contains(today)) {
      history.remove(today);
    } else {
      history.add(today);
    }
    _data.habits[i] = Habit(
      id: h.id,
      title: h.title,
      subtitle: h.subtitle,
      icon: h.icon,
      tone: h.tone,
      kind: h.kind,
      history: history,
    );
    _commit();
  }

  Habit? deleteHabit(String id) {
    final i = _data.habits.indexWhere((h) => h.id == id);
    if (i == -1) return null;
    final removed = _data.habits.removeAt(i);
    _commit();
    return removed;
  }

  void restoreHabit(Habit habit) {
    _data.habits.insert(0, habit);
    _commit();
  }

  // ------------------------------------------------------- journal & mood

  void addEntry({required String text, required Mood mood}) {
    final date = dateKey();
    _data.entries.insert(
      0,
      Entry(
        id: _uid(),
        text: text.trim(),
        mood: mood,
        date: date,
        ts: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _data.moods[date] = mood;
    _commit();
  }

  Entry? deleteEntry(String id) {
    final i = _data.entries.indexWhere((e) => e.id == id);
    if (i == -1) return null;
    final removed = _data.entries.removeAt(i);
    _commit();
    return removed;
  }

  void restoreEntry(Entry entry) {
    _data.entries.insert(0, entry);
    _commit();
  }

  void setMoodToday(Mood mood) {
    _data.moods[dateKey()] = mood;
    _commit();
  }

  void setDark(bool value) {
    _data.dark = value;
    _commit();
  }

  void setName(String value) {
    _data.name = value.trim();
    _commit();
  }

  void resetToSample() {
    final seed = sampleData();
    _data.tasks
      ..clear()
      ..addAll(seed.tasks);
    _data.habits
      ..clear()
      ..addAll(seed.habits);
    _data.entries
      ..clear()
      ..addAll(seed.entries);
    _data.moods
      ..clear()
      ..addAll(seed.moods);
    _data.dark = seed.dark;
    _commit();
  }

  // ---------------------------------------------------------- persistence

  Map<String, dynamic> toJson() => {
    'name': _data.name,
    'tasks': _data.tasks.map((t) => t.toJson()).toList(),
    'habits': _data.habits.map((h) => h.toJson()).toList(),
    'entries': _data.entries.map((e) => e.toJson()).toList(),
    'moods': _data.moods.map((k, v) => MapEntry(k, v.label)),
    'dark': _data.dark,
  };

  static Future<BloomStore> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return BloomStore(
          StoreData(
            tasks: (map['tasks'] as List? ?? [])
                .map((e) => Task.fromJson(e as Map<String, dynamic>))
                .toList(),
            habits: (map['habits'] as List? ?? [])
                .map((e) => Habit.fromJson(e as Map<String, dynamic>))
                .toList(),
            entries: (map['entries'] as List? ?? [])
                .map((e) => Entry.fromJson(e as Map<String, dynamic>))
                .toList(),
            moods: (map['moods'] as Map? ?? {}).map(
              (k, v) => MapEntry(k as String, Mood.fromLabel(v as String?)),
            ),
            dark: map['dark'] as bool? ?? false,
            name: map['name'] as String? ?? '',
          ),
        );
      }
    } catch (_) {
      // Corrupt or unavailable storage — start empty rather than inventing data.
    }
    return BloomStore(emptyData());
  }

  Future<void> _commit() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(toJson()));
    } catch (_) {
      // Storage unavailable — the prototype still works in memory.
    }
  }
}

/// A brand-new install. The app starts with the user's own (empty) space, not
/// a demo persona; sample content is only loaded when explicitly requested.
StoreData emptyData() => StoreData(
  tasks: const <Task>[],
  habits: const <Habit>[],
  entries: const <Entry>[],
  moods: const <String, Mood>{},
  dark: false,
);

StoreData sampleData() {
  final today = dateKey();
  final now = DateTime.now();

  List<String> streakDays(int n, bool includeToday) => List.generate(
    n,
    (i) => dateKey(addDays(now, -(includeToday ? i : i + 1))),
  );

  return StoreData(
    tasks: [
      Task(
        id: _uid(),
        title: 'Read 10 pages of Atomic Habits',
        category: TaskCategory.personal,
        time: '8:00 AM',
        done: true,
        doneOn: today,
      ),
      Task(
        id: _uid(),
        title: 'Finish the landing page design',
        category: TaskCategory.work,
        time: '10:00 AM',
      ),
      Task(
        id: _uid(),
        title: '30-minute walk in the park',
        category: TaskCategory.wellness,
        time: '5:30 PM',
      ),
      Task(
        id: _uid(),
        title: 'Plan tomorrow, unplug tonight',
        category: TaskCategory.personal,
        time: '9:00 PM',
      ),
    ],
    habits: [
      Habit(
        id: _uid(),
        title: 'Drink more water',
        subtitle: '8 glasses a day',
        icon: BloomIcon.water,
        tone: HabitTone.sky,
        kind: HabitKind.build,
        history: streakDays(12, true),
      ),
      Habit(
        id: _uid(),
        title: 'Mindful mornings',
        subtitle: '10 minutes of meditation',
        icon: BloomIcon.sun,
        tone: HabitTone.peach,
        kind: HabitKind.build,
        history: streakDays(8, false),
      ),
      Habit(
        id: _uid(),
        title: 'Less screen time',
        subtitle: 'No phone before bed',
        icon: BloomIcon.moon,
        tone: HabitTone.lilac,
        kind: HabitKind.breaking,
        history: streakDays(5, true),
      ),
      Habit(
        id: _uid(),
        title: 'Move your body',
        subtitle: '20 minutes of movement',
        icon: BloomIcon.run,
        tone: HabitTone.rose,
        kind: HabitKind.build,
        history: streakDays(3, false),
      ),
    ],
    entries: [
      Entry(
        id: _uid(),
        text: 'Took the long way home today and it cleared my head. Small win, but it counts.',
        mood: Mood.good,
        date: dateKey(addDays(now, -1)),
        ts: addDays(now, -1).millisecondsSinceEpoch,
      ),
    ],
    moods: {dateKey(addDays(now, -1)): Mood.good},
    dark: false,
  );
}

/// Gives widgets access to the store and rebuilds them when it changes.
class BloomScope extends InheritedNotifier<BloomStore> {
  const BloomScope({super.key, required BloomStore store, required super.child})
    : super(notifier: store);

  static BloomStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BloomScope>();
    assert(scope != null, 'BloomScope is missing above this widget');
    return scope!.notifier!;
  }
}
