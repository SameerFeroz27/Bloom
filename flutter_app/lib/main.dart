import 'package:flutter/material.dart';

import 'app.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await BloomStore.load();
  runApp(BloomApp(store: store));
}
