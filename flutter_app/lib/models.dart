import 'package:flutter/material.dart';

/// Bottom navigation destinations.
enum BloomTab {
  home('Home', BloomIcon.home),
  tasks('Tasks', BloomIcon.check),
  habits('Habits', BloomIcon.leaf),
  journal('Journal', BloomIcon.book),
  insights('Insights', BloomIcon.chart);

  const BloomTab(this.label, this.icon);

  final String label;
  final BloomIcon icon;
}

/// Icon set from the prototype's SVG sprites, mapped onto Material icons.
enum BloomIcon {
  home(Icons.home_outlined),
  check(Icons.check),
  leaf(Icons.eco_outlined),
  book(Icons.menu_book_outlined),
  chart(Icons.bar_chart),
  plus(Icons.add),
  bell(Icons.notifications_none),
  chevron(Icons.chevron_right),
  fire(Icons.local_fire_department),
  water(Icons.water_drop_outlined),
  sun(Icons.wb_sunny_outlined),
  moon(Icons.dark_mode_outlined),
  close(Icons.close),
  search(Icons.search),
  trash(Icons.delete_outline),
  spark(Icons.auto_awesome),
  arrow(Icons.arrow_forward),
  run(Icons.directions_run),
  heart(Icons.favorite_border),
  pencil(Icons.edit_outlined),
  undo(Icons.undo),
  user(Icons.person_outline),
  trophy(Icons.emoji_events_outlined),
  clock(Icons.schedule),
  more(Icons.more_horiz),
  target(Icons.gps_fixed),
  settings(Icons.settings_outlined),
  wind(Icons.air);

  const BloomIcon(this.data);

  final IconData data;

  static BloomIcon fromName(String? name) =>
      BloomIcon.values.firstWhere((i) => i.name == name, orElse: () => BloomIcon.leaf);
}

/// The `tone-*` accent pairs, light and dark. Names match the CSS/JSON keys.
enum HabitTone {
  green(Color(0xFFDFE9D3), Color(0xFF37592B), Color(0xFF2C4524), Color(0xFFB6D7A6)),
  sky(Color(0xFFD9E9F8), Color(0xFF2F5C85), Color(0xFF1F3A54), Color(0xFFB0D4F2)),
  peach(Color(0xFFF8E4C8), Color(0xFF7D5527), Color(0xFF55401F), Color(0xFFF4CF96)),
  lilac(Color(0xFFE7E0F6), Color(0xFF554A7E), Color(0xFF3F365F), Color(0xFFD4C8F4)),
  rose(Color(0xFFF8DADE), Color(0xFF8A3F4B), Color(0xFF57303A), Color(0xFFF4BCC6)),
  sand(Color(0xFFEEE3CD), Color(0xFF6F5D3A), Color(0xFF4D4128), Color(0xFFE8D5AD));

  const HabitTone(this.lightBg, this.lightFg, this.darkBg, this.darkFg);

  final Color lightBg;
  final Color lightFg;
  final Color darkBg;
  final Color darkFg;

  Color bg(Brightness brightness) => brightness == Brightness.dark ? darkBg : lightBg;

  Color fg(Brightness brightness) => brightness == Brightness.dark ? darkFg : lightFg;

  static HabitTone fromName(String? name) =>
      HabitTone.values.firstWhere((t) => t.name == name, orElse: () => HabitTone.sky);
}

enum TaskCategory {
  personal('Personal', Color(0xFFECE6F6), Color(0xFF66558B), Color(0xFF3B3352), Color(0xFFCABEF0)),
  work('Work', Color(0xFFDDEBF9), Color(0xFF41678E), Color(0xFF294258), Color(0xFFB3D2EE)),
  wellness('Wellness', Color(0xFFE0EDDA), Color(0xFF4D7440), Color(0xFF2E4327), Color(0xFFB6D6A8));

  const TaskCategory(this.label, this.lightBg, this.lightFg, this.darkBg, this.darkFg);

  final String label;
  final Color lightBg;
  final Color lightFg;
  final Color darkBg;
  final Color darkFg;

  Color bg(Brightness brightness) => brightness == Brightness.dark ? darkBg : lightBg;

  Color fg(Brightness brightness) => brightness == Brightness.dark ? darkFg : lightFg;

  static TaskCategory fromLabel(String? s) =>
      TaskCategory.values.firstWhere((c) => c.label == s, orElse: () => TaskCategory.personal);
}

enum Mood {
  low('Low'),
  okay('Okay'),
  good('Good'),
  great('Great'),
  amazing('Amazing');

  const Mood(this.label);

  final String label;

  static Mood fromLabel(String? s) =>
      Mood.values.firstWhere((m) => m.label == s, orElse: () => Mood.good);
}

enum HabitKind {
  build('Build', 'I want to build'),
  breaking('Break', 'I want to break');

  const HabitKind(this.label, this.choice);

  final String label;
  final String choice;

  static HabitKind fromLabel(String? s) =>
      HabitKind.values.firstWhere((k) => k.label == s, orElse: () => HabitKind.build);
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    this.done = false,
    this.doneOn,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final String time;
  final bool done;
  final String? doneOn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.label,
    'time': time,
    'done': done,
    if (doneOn != null) 'doneOn': doneOn,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    category: TaskCategory.fromLabel(j['category'] as String?),
    time: j['time'] as String? ?? 'Anytime',
    done: j['done'] as bool? ?? false,
    doneOn: j['doneOn'] as String?,
  );
}

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.kind,
    required this.history,
  });

  final String id;
  final String title;
  final String subtitle;
  final BloomIcon icon;
  final HabitTone tone;
  final HabitKind kind;

  /// Day keys (`yyyy-MM-dd`) the habit was completed on.
  final List<String> history;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.name,
    'color': tone.name,
    'kind': kind.label,
    'history': history,
  };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    subtitle: j['subtitle'] as String? ?? '',
    icon: BloomIcon.fromName(j['icon'] as String?),
    tone: HabitTone.fromName(j['color'] as String?),
    kind: HabitKind.fromLabel(j['kind'] as String?),
    history: (j['history'] as List?)?.map((e) => e as String).toList() ?? const [],
  );
}

class Entry {
  const Entry({
    required this.id,
    required this.text,
    required this.mood,
    required this.date,
    required this.ts,
  });

  final String id;
  final String text;
  final Mood mood;
  final String date;
  final int ts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'mood': mood.label,
    'date': date,
    'ts': ts,
  };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    id: j['id'] as String,
    text: j['text'] as String? ?? '',
    mood: Mood.fromLabel(j['mood'] as String?),
    date: j['date'] as String? ?? '',
    ts: (j['ts'] as num?)?.toInt() ?? 0,
  );
}

class StoreData {
  StoreData({
    required List<Task> tasks,
    required List<Habit> habits,
    required List<Entry> entries,
    required Map<String, Mood> moods,
    required this.dark,
    this.name = '',
  }) : tasks = List<Task>.of(tasks),
       habits = List<Habit>.of(habits),
       entries = List<Entry>.of(entries),
       moods = Map<String, Mood>.of(moods);

  final List<Task> tasks;
  final List<Habit> habits;
  final List<Entry> entries;
  final Map<String, Mood> moods;
  bool dark;

  /// Empty until the user adds a name from Profile.
  String name;
}
