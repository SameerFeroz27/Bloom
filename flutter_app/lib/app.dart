import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/habits_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/tasks_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/sheets.dart';

final ThemeData _lightTheme = bloomTheme(Brightness.light);
final ThemeData _darkTheme = bloomTheme(Brightness.dark);

class BloomApp extends StatelessWidget {
  const BloomApp({super.key, required this.store});

  final BloomStore store;

  @override
  Widget build(BuildContext context) {
    return BloomScope(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, child) => MaterialApp(
          title: 'bloom.',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
        child: const _Shell(),
      ),
    );
  }
}

/// On a phone the app fills the screen; on a wide window it is shown inside the
/// Pixel frame the prototype used.
class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  BloomTab _tab = BloomTab.home;

  void _openSheet(Widget sheet) => showBloomSheet(context, sheet);

  @override
  Widget build(BuildContext context) {
    // MaterialApp already provides a ScaffoldMessenger above the Navigator, so
    // modal sheets can use the same messenger as the screens beneath them.
    return _AppBody(
      tab: _tab,
      onTab: (tab) => setState(() => _tab = tab),
      onNewTask: () => _openSheet(const NewTaskSheet()),
      onNewHabit: () => _openSheet(const NewHabitSheet()),
      onNotifs: () => _openSheet(const NotifsSheet()),
      onProfile: () => _openSheet(const ProfileSheet()),
    );
  }
}

class _AppBody extends StatelessWidget {
  const _AppBody({
    required this.tab,
    required this.onTab,
    required this.onNewTask,
    required this.onNewHabit,
    required this.onNotifs,
    required this.onProfile,
  });

  final BloomTab tab;
  final ValueChanged<BloomTab> onTab;
  final VoidCallback onNewTask;
  final VoidCallback onNewHabit;
  final VoidCallback onNotifs;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final screen = switch (tab) {
      BloomTab.home => HomeScreen(
        onOpenTab: onTab,
        onNewTask: onNewTask,
        onNewHabit: onNewHabit,
      ),
      BloomTab.tasks => TasksScreen(onNewTask: onNewTask),
      BloomTab.habits => HabitsScreen(onNewHabit: onNewHabit),
      BloomTab.journal => const JournalScreen(),
      BloomTab.insights => const InsightsScreen(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: scheme.surface,
            systemNavigationBarIconBrightness:
                Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              _TopBar(tab: tab, onNotifs: onNotifs, onProfile: onProfile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    2,
                    16,
                    tab == BloomTab.insights ? 26 : 112,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(tab), child: screen),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: tab == BloomTab.insights
            ? null
            : _Fab(
                icon: tab == BloomTab.habits ? BloomIcon.leaf : BloomIcon.plus,
                tooltip: tab == BloomTab.habits ? 'New habit' : 'New task',
                onTap: tab == BloomTab.habits ? onNewHabit : onNewTask,
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _NavBar(tab: tab, onTab: onTab),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.tab, required this.onNotifs, required this.onProfile});

  final BloomTab tab;
  final VoidCallback onNotifs;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String initial = initialOf(BloomScope.of(context).name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const _BrandMark(size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bloom.',
                    style: BloomText.display(18, FontWeight.w800, letterSpacing: -0.5),
                  ),
                  Text(
                    tab.label,
                    style: BloomText.body(
                      10,
                      FontWeight.w400,
                      letterSpacing: 0.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Notifications',
              container: true,
              excludeSemantics: true,
              onTap: onNotifs,
              child: InkWell(
                onTap: onNotifs,
                borderRadius: BorderRadius.circular(19),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(BloomIcon.bell.data, size: 20, color: scheme.onSurface),
                      Positioned(
                        top: 9,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Profile',
              container: true,
              excludeSemantics: true,
              onTap: onProfile,
              child: InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: initial.isEmpty
                      ? Icon(
                          Icons.person_outline,
                          size: 20,
                          color: scheme.onPrimaryContainer,
                        )
                      : Text(
                          initial,
                          style: BloomText.body(
                            14,
                            FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'bloom logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: BloomExtras.of(context).shadow1,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/branding/bloom_logo.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.icon, required this.tooltip, required this.onTap});

  final BloomIcon icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
            boxShadow: extras.shadow2,
          ),
          child: Icon(icon.data, size: 26, color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onTab});

  final BloomTab tab;
  final ValueChanged<BloomTab> onTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(6, 10, 6, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: 0.88),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final item in BloomTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: item == tab,
                label: 'Open ${item.label} tab',
                container: true,
                excludeSemantics: true,
                onTap: () => onTab(item),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTab(item),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: 58,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item == tab ? scheme.secondaryContainer : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon.data,
                          size: 21,
                          color: item == tab ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        style: BloomText.body(
                          11,
                          FontWeight.w600,
                          letterSpacing: 0.1,
                          color: item == tab
                              ? scheme.onSecondaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

