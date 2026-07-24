import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/calcul_result.dart';
import '../models/ratio_ferraillage.dart';

/// Béton, parpaings, mortier, ferraillage (DTU 21, BAEL / EC2).
class GrosOeuvreEngine {
  GrosOeuvreEngine._();

  static const double densiteAcier = 7850.0;
  static const double epaisseurJointM = 0.010;

  static CalculResult volumeBeton({
    required double longueur,
    required double largeur,
    required double epaisseur,
    double coefficientPerte = AppConstants.perteBeton,
  }) {
    _assertPositif(longueur, largeur, epaisseur);
    _assertPerte(coefficientPerte, min: 0.01, max: 0.10);
    final volumeNet = longueur * largeur * epaisseur;
    final volumeAvecPerte = volumeNet * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: volumeAvecPerte,
      unite: 'm³',
      designation: 'Béton dalle',
      details: {
        'volume_net': volumeNet,
        'coefficient_perte': coefficientPerte,
        'longueur': longueur,
        'largeur': largeur,
        'epaisseur': epaisseur,
      },
      referenceNormative:
          '${NormativeRefs.dtuBeton}, ${NormativeRefs.baelEurocode}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult nombreParpaings({
    required double longueurMur,
    required double hauteurMur,
    double longueurParpaing = 0.50,
    double hauteurParpaing = 0.20,
    double coefficientPerte = AppConstants.perteParpaing,
  }) {
    _assertPositif(longueurMur, hauteurMur, longueurParpaing);
    if (hauteurParpaing <= 0) {
      throw ArgumentError('Hauteur parpaing doit être > 0.');
    }
    _assertPerte(coefficientPerte, min: 0.01, max: 0.20);
    final surfaceMur = longueurMur * hauteurMur;
    final surfaceParpaing = longueurParpaing * hauteurParpaing;
    final nbNet = surfaceMur / surfaceParpaing;
    final nbAvecPerte = (nbNet * (1 + coefficientPerte)).ceil();
    return CalculResult(
      valeurPrincipale: nbAvecPerte.toDouble(),
      unite: 'unités',
      designation: 'Parpaings',
      details: {
        'surface_mur': surfaceMur,
        'surface_parpaing': surfaceParpaing,
        'nb_net': nbNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: NormativeRefs.dtuBeton,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Volume de mortier de pose approximatif (joints horizontaux + verticaux).
  static CalculResult volumeMortier({
    required double nombreParpaings,
    double longueurParpaing = 0.50,
    double hauteurParpaing = 0.20,
    double profondeurParpaing = 0.20,
    double epaisseurJoint = epaisseurJointM,
  }) {
    if (nombreParpaings <= 0) {
      throw ArgumentError('Le nombre de parpaings doit être > 0.');
    }
    final jointHorizontal =
        longueurParpaing * profondeurParpaing * epaisseurJoint;
    final jointVertical =
        hauteurParpaing * profondeurParpaing * epaisseurJoint;
    final volume = nombreParpaings * (jointHorizontal + jointVertical);
    return CalculResult(
      valeurPrincipale: volume,
      unite: 'm³',
      designation: 'Mortier de pose',
      details: {
        'nombre_parpaings': nombreParpaings,
        'epaisseur_joint_m': epaisseurJoint,
        'joint_horizontal_unitaire': jointHorizontal,
        'joint_vertical_unitaire': jointVertical,
      },
      referenceNormative: NormativeRefs.dtuBeton,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult quantiteAcier({
    required double volumeBeton,
    required RatioFerraillage ratio,
  }) {
    if (volumeBeton <= 0) {
      throw ArgumentError('Le volume de béton doit être > 0.');
    }
    final masseAcier = volumeBeton * ratio.valeurKgM3;
    return CalculResult(
      valeurPrincipale: masseAcier,
      unite: 'kg',
      designation: 'Acier — ${ratio.libelle}',
      details: {
        'volume_beton': volumeBeton,
        'ratio_kg_m3': ratio.valeurKgM3,
        'element': ratio.typeElement,
      },
      referenceNormative:
          '${NormativeRefs.baelEurocode} — ${ratio.sourceNormative}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  static void _assertPositif(double a, double b, double c) {
    if (a <= 0 || b <= 0 || c <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
  }

  static void _assertPerte(double c, {required double min, required double max}) {
    if (c < min || c > max) {
      throw ArgumentError(
        'Coefficient de perte hors plage [${(min * 100).toInt()}%, ${(max * 100).toInt()}%].',
      );
    }
  }
}
