/// Garde freemium côté client (miroir de EstAbonne côté serveur).
abstract final class FreemiumGuard {
  static const Set<String> fonctionnalitesAvancees = {
    'plan_image',
    'export_pdf',
    'export_excel',
    'synchronisation',
    'devis_export',
    'analyse_ia',
  };

  static bool peutAcceder({
    required bool estConnecte,
    required bool estAbonne,
    required String fonctionnalite,
  }) {
    if (!fonctionnalitesAvancees.contains(fonctionnalite)) return true;
    return estConnecte && estAbonne;
  }
}
