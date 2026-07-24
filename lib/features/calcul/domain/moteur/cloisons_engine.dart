import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/calcul_result.dart';

/// Cloisons, doublages, plafonds (DTU 25.41 / 58.1).
class CloisonsEngine {
  CloisonsEngine._();

  static CalculResult surfaceCloison({
    required double longueurPiece,
    required double largeurPiece,
    required double hauteurPiece,
    String typeMateriau = 'plaque_platre',
    double coefficientPerte = AppConstants.perteCloisons,
  }) {
    _assertPositif(longueurPiece, largeurPiece, hauteurPiece);
    _assertPerte(coefficientPerte);
    final perimetre = 2 * (longueurPiece + largeurPiece);
    final surfaceNette = perimetre * hauteurPiece;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      designation: 'Cloisons ($typeMateriau)',
      details: {
        'surface_nette': surfaceNette,
        'perimetre': perimetre,
        'type_materiau': typeMateriau,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuCloisons,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult surfaceDoublage({
    required double longueurParoi,
    required double hauteurParoi,
    String typeMateriau = 'placomur',
    double coefficientPerte = AppConstants.perteCloisons,
  }) {
    if (longueurParoi <= 0 || hauteurParoi <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
    _assertPerte(coefficientPerte);
    final surfaceNette = longueurParoi * hauteurParoi;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      designation: 'Doublage ($typeMateriau)',
      details: {
        'surface_nette': surfaceNette,
        'type_materiau': typeMateriau,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuCloisons,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult surfacePlafond({
    required double longueur,
    required double largeur,
    double coefficientPerte = AppConstants.perteCloisons,
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
      designation: 'Plafond',
      details: {
        'surface_nette': surfaceNette,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuPlafonds,
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
