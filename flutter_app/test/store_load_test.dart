import 'package:bloom/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install starts empty instead of loading sample data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final BloomStore store = await BloomStore.load();

    expect(store.tasks, isEmpty);
    expect(store.habits, isEmpty);
    expect(store.entries, isEmpty);
    expect(store.moods, isEmpty);
  });
}
