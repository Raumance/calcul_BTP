import 'dart:math';

import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/bloc.dart';
import '../models/calcul_result.dart';
import '../models/ciment.dart';
import '../models/ferraillage.dart';
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
    TypeParpaing typeParpaing = TypeParpaing.parpaing50x20x20,
    double coefficientPerte = AppConstants.perteParpaing,
  }) {
    _assertPositif(longueurMur, hauteurMur, typeParpaing.longueurM);
    _assertPerte(coefficientPerte, min: 0.01, max: 0.20);
    final surfaceMur = longueurMur * hauteurMur;
    final surfaceParpaing = typeParpaing.surface;
    final nbNet = surfaceMur / surfaceParpaing;
    final nbAvecPerte = (nbNet * (1 + coefficientPerte)).ceil();
    return CalculResult(
      valeurPrincipale: nbAvecPerte.toDouble(),
      unite: 'unités',
      designation: 'Parpaings — ${typeParpaing.dimensions}',
      details: {
        'surface_mur': surfaceMur,
        'surface_parpaing': surfaceParpaing,
        'type_parpaing': typeParpaing.libelle,
        'categorie_parpaing': typeParpaing.categorie,
        'dimensions_parpaing': typeParpaing.dimensions,
        'nb_net': nbNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: '${NormativeRefs.dtuBeton}, ${NormativeRefs.nfC15100}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Volume de mortier de pose approximatif (joints horizontaux + verticaux).
  static CalculResult volumeMortier({
    required double nombreParpaings,
    TypeParpaing typeParpaing = TypeParpaing.parpaing50x20x20,
    double profondeurParpaing = 0.20,
    double epaisseurJoint = epaisseurJointM,
  }) {
    if (nombreParpaings <= 0) {
      throw ArgumentError('Le nombre de parpaings doit être > 0.');
    }
    final jointHorizontal =
        typeParpaing.longueurM * profondeurParpaing * epaisseurJoint;
    final jointVertical =
        typeParpaing.hauteurM * profondeurParpaing * epaisseurJoint;
    final volume = nombreParpaings * (jointHorizontal + jointVertical);
    return CalculResult(
      valeurPrincipale: volume,
      unite: 'm³',
      designation: 'Mortier de pose',
      details: {
        'nombre_parpaings': nombreParpaings,
        'type_parpaing': typeParpaing.libelle,
        'dimensions_parpaing': typeParpaing.dimensions,
        'epaisseur_joint_m': epaisseurJoint,
        'joint_horizontal_unitaire': jointHorizontal,
        'joint_vertical_unitaire': jointVertical,
      },
      referenceNormative: '${NormativeRefs.dtuBeton}, ${NormativeRefs.nfC15100}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult nombreBriques({
    required double longueurMur,
    required double hauteurMur,
    required TypeBrique typeBrique,
    double coefficientPerte = AppConstants.perteParpaing,
  }) {
    _assertPositif(longueurMur, hauteurMur, typeBrique.longueurM);
    _assertPerte(coefficientPerte, min: 0.01, max: 0.20);
    final surfaceMur = longueurMur * hauteurMur;
    final surfaceBrique = typeBrique.surface;
    final nbNet = surfaceMur / surfaceBrique;
    final nbAvecPerte = (nbNet * (1 + coefficientPerte)).ceil();
    return CalculResult(
      valeurPrincipale: nbAvecPerte.toDouble(),
      unite: 'unités',
      designation: 'Briques — ${typeBrique.dimensions}',
      details: {
        'surface_mur': surfaceMur,
        'surface_brique': surfaceBrique,
        'type_brique': typeBrique.libelle,
        'dimensions_brique': typeBrique.dimensions,
        'nb_net': nbNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: '${NormativeRefs.dtuBeton}, ${NormativeRefs.nfC15100}',
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
      },
      referenceNormative:
          '${NormativeRefs.baelEurocode} — ${ratio.sourceNormative}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Détaille la quantification des barres et étriers à partir de la masse d'acier
  /// et des paramètres de section/équipements (longueur tige = 12 m par défaut).
  static CalculResult quantiteAcierDetail({
    required double volumeBeton,
    required RatioFerraillage ratio,
    TypeAcier typeAcier = TypeAcier.feE400,
    SectionType sectionType = SectionType.carre,
    double longueurPoteau = 3.0,
    double largeurPoteau = 0.3,
    double hauteurPoteau = 0.3,
    double diametreEtrierMm = 8,
    double pasEtrier = 0.20,
    double longueurTige = 12.0,
  }) {
    if (volumeBeton <= 0) {
      throw ArgumentError('Le volume de béton doit être > 0.');
    }
    final masseAcier = volumeBeton * ratio.valeurKgM3;
    final longueurTotaleBarre = masseAcier / typeAcier.masseParMetre;
    final nbBarres = (longueurTotaleBarre / longueurTige).ceil();

    final crossSection = _sectionSurface(
      type: sectionType,
      largeur: largeurPoteau,
      hauteur: hauteurPoteau,
    );
    final nbEtriers = _calculerNombreEtriers(
      longueur: longueurPoteau,
      pas: pasEtrier,
    );
    final masseEtriers = nbEtriers * (diametreEtrierMm / 1000.0) * 3.14 * 0.01;

    return CalculResult(
      valeurPrincipale: nbBarres.toDouble(),
      unite: 'barres',
      designation: 'Acier détaillé — ${ratio.libelle}',
      details: {
        'volume_beton': volumeBeton,
        'ratio_kg_m3': ratio.valeurKgM3,
        'type_acier': typeAcier.libelle,
        'section_type': sectionType.libelle,
        'section_surface_m2': crossSection,
        'longueur_poteau_m': longueurPoteau,
        'largeur_poteau_m': largeurPoteau,
        'hauteur_poteau_m': hauteurPoteau,
        'diametre_etrier_mm': diametreEtrierMm,
        'pas_etrier_m': pasEtrier,
        'nombre_etriers': nbEtriers,
        'masse_etriers_kg': masseEtriers,
        'longueur_totale_barres_m': longueurTotaleBarre,
        'nombre_barres_12m': nbBarres,
      },
      referenceNormative:
          '${NormativeRefs.baelEurocode} — ${ratio.sourceNormative}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  static double _sectionSurface({
    required SectionType type,
    required double largeur,
    required double hauteur,
  }) {
    switch (type) {
      case SectionType.carre:
      case SectionType.rectangulaire:
        return largeur * hauteur;
      case SectionType.circulaire:
        return (pi / 4) * largeur * largeur;
    }
  }

  static int _calculerNombreEtriers({
    required double longueur,
    required double pas,
  }) {
    if (longueur <= 0 || pas <= 0) return 0;
    return (longueur / pas).ceil();
  }

  static CalculResult quantiteCiment({
    required double volumeBeton,
    required DosageBeton dosage,
    required TypeCiment typeCiment,
    required SacCiment sacCiment,
  }) {
    if (volumeBeton <= 0) {
      throw ArgumentError('Le volume de béton doit être > 0.');
    }
    final masseCiment = volumeBeton * dosage.valeurKgM3;
    final nombreSacs = (masseCiment / sacCiment.poidsKg).ceil();
    return CalculResult(
      valeurPrincipale: nombreSacs.toDouble(),
      unite: 'sacs',
      designation: 'Ciment — ${typeCiment.libelle}',
      details: {
        'volume_beton': volumeBeton,
        'dosage_kg_m3': dosage.valeurKgM3,
        'type_ciment': typeCiment.libelle,
        'masse_ciment_kg': masseCiment,
        'poids_sac_kg': sacCiment.poidsKg,
        'nombre_sacs': nombreSacs,
      },
      referenceNormative:
          '${NormativeRefs.dtuBeton} — ${dosage.libelle}',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Quantité de ciment nécessaire pour un volume de mortier.
  /// - [volumeMortier] en m³
  /// - [dosageKgM3] masse de ciment appliquée par m³ de mortier (kg/m³)
  static CalculResult quantiteCimentMortier({
    required double volumeMortier,
    required double dosageKgM3,
    required TypeCiment typeCiment,
    required SacCiment sacCiment,
  }) {
    if (volumeMortier <= 0) {
      throw ArgumentError('Le volume de mortier doit être > 0.');
    }
    if (dosageKgM3 <= 0) {
      throw ArgumentError('Le dosage ciment (kg/m³) doit être > 0.');
    }
    final masseCiment = volumeMortier * dosageKgM3;
    final nombreSacs = (masseCiment / sacCiment.poidsKg).ceil();
    return CalculResult(
      valeurPrincipale: nombreSacs.toDouble(),
      unite: 'sacs',
      designation: 'Ciment pour mortier — ${typeCiment.libelle}',
      details: {
        'volume_mortier_m3': volumeMortier,
        'dosage_ciment_kg_m3': dosageKgM3,
        'masse_ciment_kg': masseCiment,
        'poids_sac_kg': sacCiment.poidsKg,
        'nombre_sacs': nombreSacs,
      },
      referenceNormative: '${NormativeRefs.dtuBeton}, ${NormativeRefs.nfC15100}',
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
