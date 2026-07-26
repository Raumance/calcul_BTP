import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/calcul_result.dart';
import '../models/carreau.dart';

class Ouverture {
  const Ouverture({required this.largeur, required this.hauteur});
  final double largeur;
  final double hauteur;
  double get surface => largeur * hauteur;
}

/// Peinture, papier peint, carrelage (DTU 59.1 / 59.4 / 52.1).
class FinitionsEngine {
  FinitionsEngine._();

  static CalculResult surfacePeinture({
    required double longueur,
    required double largeur,
    required double hauteur,
    List<Ouverture> ouvertures = const [],
    bool inclurePlafond = true,
    double coefficientPerte = AppConstants.perteFinitions,
  }) {
    _assertPositif(longueur, largeur, hauteur);
    _assertPerte(coefficientPerte);
    final surfaceMurs = 2 * (longueur + largeur) * hauteur;
    final surfacePlafond = inclurePlafond ? longueur * largeur : 0.0;
    final surfaceTotale = surfaceMurs + surfacePlafond;
    final deduction =
        ouvertures.fold<double>(0, (s, o) => s + o.surface);
    final surfaceNette = (surfaceTotale - deduction).clamp(0.0, double.infinity);
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      designation: 'Peinture',
      details: {
        'surface_totale': surfaceTotale,
        'deduction_ouvertures': deduction,
        'surface_nette': surfaceNette,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuPeinture,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult nombreRouleaux({
    required double surfaceATapisser,
    required double hauteurRouleau,
    required double laize,
    double coefficientPerte = AppConstants.perteFinitions,
  }) {
    if (surfaceATapisser <= 0 || hauteurRouleau <= 0 || laize <= 0) {
      throw ArgumentError('Les valeurs doivent être strictement positives.');
    }
    _assertPerte(coefficientPerte);
    final surfaceRouleau = hauteurRouleau * laize;
    final nb =
        (surfaceATapisser * (1 + coefficientPerte) / surfaceRouleau).ceil();
    return CalculResult(
      valeurPrincipale: nb.toDouble(),
      unite: 'rouleaux',
      designation: 'Papier peint',
      details: {
        'surface_rouleau': surfaceRouleau,
        'surface_a_tapisser': surfaceATapisser,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuPapierPeint,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult surfaceCarrelage({
    required double longueur,
    required double largeur,
    double coefficientPerte = AppConstants.perteCarrelage,
  }) {
    if (longueur <= 0 || largeur <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
    _assertPerte(coefficientPerte);
    final surfaceNette = longueur * largeur;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      designation: 'Carrelage',
      details: {
        'surface_nette': surfaceNette,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuCarrelage,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult nombreCarreaux({
    required double longueur,
    required double largeur,
    required TypeCarreau typeCarreau,
    double coefficientPerte = AppConstants.perteCarrelage,
  }) {
    if (longueur <= 0 || largeur <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
    _assertPerte(coefficientPerte);
    final surfaceNette = longueur * largeur;
    final surfaceCarreau = typeCarreau.surface;
    final nbNet = surfaceNette / surfaceCarreau;
    final nbAvecPerte = (nbNet * (1 + coefficientPerte)).ceil();
    return CalculResult(
      valeurPrincipale: nbAvecPerte.toDouble(),
      unite: 'unités',
      designation: 'Carreaux — ${typeCarreau.dimensions}',
      details: {
        'surface_nette': surfaceNette,
        'surface_carreau': surfaceCarreau,
        'type_carreau': typeCarreau.libelle,
        'categorie_carreau': typeCarreau.categorie,
        'dimensions_carreau': typeCarreau.dimensions,
        'nb_net': nbNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: '${NormativeRefs.dtuCarrelage}, ${NormativeRefs.nfC15100}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  static void _assertPositif(double a, double b, double c) {
    if (a <= 0 || b <= 0 || c <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
  }

  static void _assertPerte(double c) {
    if (c < 0.01 || c > 0.20) {
      throw ArgumentError('Coefficient de perte hors plage [1%, 20%].');
    }
  }
}
