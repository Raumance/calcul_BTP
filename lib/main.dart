import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'shared/database/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final store = LocalStore();
  await store.init();

  runApp(CalculBtpApp(store: store));
}
