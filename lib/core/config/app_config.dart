import 'dart:io';

/// Configuration runtime — adapter selon plateforme / environnement.
abstract final class AppConfig {
  /// URL API locale.
  /// - Windows / desktop : localhost
  /// - Émulateur Android : 10.0.2.2
  /// - Appareil physique : IP de la machine de dev
  static String get apiBaseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String get wsBaseUrl {
    if (Platform.isAndroid) return 'ws://10.0.2.2:8000';
    return 'ws://127.0.0.1:8000';
  }

  static const bool requireAuthForSync = true;
}
