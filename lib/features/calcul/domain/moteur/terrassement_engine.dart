import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/calcul_result.dart';
import '../models/type_sol.dart';

export '../models/type_sol.dart';

/// Volumes de déblais / remblais avec foisonnement (DTU 12.1).
class TerrassementEngine {
  TerrassementEngine._();

  static CalculResult deblai({
    required double longueur,
    required double largeur,
    required double profondeur,
    required TypeSol typeSol,
  }) {
    _assertPositif(longueur, largeur, profondeur);
    final volumeEnPlace = longueur * largeur * profondeur;
    final volumeFoisonne = volumeEnPlace * typeSol.coefficientFoisonnement;
    return CalculResult(
      valeurPrincipale: volumeFoisonne,
      unite: 'm³',
      designation: 'Déblais (${typeSol.libelle})',
      details: {
        'volume_en_place': volumeEnPlace,
        'coefficient_foisonnement': typeSol.coefficientFoisonnement,
        'type_sol': typeSol.libelle,
        'longueur': longueur,
        'largeur': largeur,
        'profondeur': profondeur,
      },
      referenceNormative: NormativeRefs.dtuTerrassement,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult remblai({
    required double longueur,
    required double largeur,
    required double hauteur,
    required TypeSol typeSol,
  }) {
    _assertPositif(longueur, largeur, hauteur);
    final volumeEnPlace = longueur * largeur * hauteur;
    final volumeFoisonne = volumeEnPlace * typeSol.coefficientFoisonnement;
    return CalculResult(
      valeurPrincipale: volumeFoisonne,
      unite: 'm³',
      designation: 'Remblais (${typeSol.libelle})',
      details: {
        'volume_en_place': volumeEnPlace,
        'coefficient_foisonnement': typeSol.coefficientFoisonnement,
        'type_sol': typeSol.libelle,
        'longueur': longueur,
        'largeur': largeur,
        'hauteur': hauteur,
      },
      referenceNormative: NormativeRefs.dtuTerrassement,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static void _assertPositif(double a, double b, double c) {
    if (a <= 0 || b <= 0 || c <= 0) {
      throw ArgumentError('Les dimensions doivent être strictement positives.');
    }
  }
}
