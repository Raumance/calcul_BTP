import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'shared/database/local_store.dart';

void main() async {
  // 1. Initialisation des bindings Flutter le plus tôt possible
  final binding = WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Préserver le splash screen natif pendant l'initialisation
  // ignore: deprecated_member_use
  binding.deferFirstFrame();

  try {
    // 3. Configurations système en parallèle
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 4. Initialisation du stockage local
    final store = LocalStore();
    await store.init();

    // 5. Lancement de l'application
    runApp(CalculBtpApp(store: store));
  } finally {
    // 6. Autoriser le premier rendu
    // ignore: deprecated_member_use
    binding.allowFirstFrame();
  }
}
