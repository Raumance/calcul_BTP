/// Constantes applicatives — ergonomie chantier et pertes par défaut.
abstract final class AppConstants {
  static const String appName = 'Calculs BTP';
  static const String disclaimerText =
      'Résultats fournis à titre indicatif. '
      'Ne remplacent pas l\'avis d\'un professionnel qualifié. '
      'L\'application réalise des quantitatifs estimatifs, '
      'pas du dimensionnement structurel certifié.';

  static const double minTouchTarget = 48.0;
  static const Duration calculTimeout = Duration(milliseconds: 200);
  static const Duration syncDebounce = Duration(seconds: 30);
  static const Duration jwtAccessLifetime = Duration(hours: 1);
  static const Duration jwtRefreshLifetime = Duration(days: 7);

  static const double perteBeton = 0.03;
  static const double perteParpaing = 0.05;
  static const double perteCarrelage = 0.10;
  static const double perteCloisons = 0.10;
  static const double perteFinitions = 0.10;
}
