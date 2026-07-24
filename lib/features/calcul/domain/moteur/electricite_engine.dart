import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/constants/normative_refs.dart';
import '../models/calcul_result.dart';

/// Sections câbles normalisées (mm²) — NF C 15-100.
const List<double> sectionsNormalisees = [1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0];

/// Calibres disjoncteurs normalisés (A) — NF C 15-100.
const List<int> calibresNormalises = [10, 16, 20, 25, 32, 40, 63];

class Circuit {
  const Circuit({
    required this.designation,
    required this.puissanceW,
    required this.longueurM,
  });

  final String designation;
  final double puissanceW;
  final double longueurM;
}

/// Calculs électriques conformes NF C 15-100.
class ElectriciteEngine {
  ElectriciteEngine._();

  static CalculResult bilanPuissance({required List<Circuit> circuits}) {
    final puissanceTotale =
        circuits.fold<double>(0, (s, c) => s + c.puissanceW);
    return CalculResult(
      valeurPrincipale: puissanceTotale,
      unite: 'W',
      designation: 'Bilan de puissance',
      details: {
        'nb_circuits': circuits.length.toDouble(),
        'puissance_kva': puissanceTotale / 1000,
      },
      referenceNormative: NormativeRefs.nfC15100,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Section minimale par chute de tension admissible (3 %).
  /// S = (2 × ρ × L × I) / (ΔU_max)
  static CalculResult sectionCable({
    required double puissanceW,
    required double longueurM,
    required double tensionV,
    required bool estCuivre,
    double facteurPuissance = 0.8,
    double chuteAdmissible = 0.03,
  }) {
    if (puissanceW <= 0 || longueurM <= 0) {
      throw ArgumentError('Puissance et longueur doivent être > 0.');
    }
    if (tensionV != 230 && tensionV != 400) {
      throw ArgumentError('Tension nominale : 230 V ou 400 V.');
    }
    final rho = estCuivre ? 0.0225 : 0.036;
    final intensite = puissanceW / (tensionV * facteurPuissance);
    final chuteMax = chuteAdmissible * tensionV;
    final sectionCalc = (2 * rho * longueurM * intensite) / chuteMax;
    final sectionNorm = sectionsNormalisees.firstWhere(
      (s) => s >= sectionCalc,
      orElse: () => sectionsNormalisees.last,
    );
    return CalculResult(
      valeurPrincipale: sectionNorm,
      unite: 'mm²',
      designation: 'Section de câble',
      details: {
        'section_calculee': sectionCalc,
        'intensite_A': intensite,
        'conducteur': estCuivre ? 'cuivre' : 'aluminium',
        'tension_V': tensionV,
        'longueur_m': longueurM,
      },
      referenceNormative: NormativeRefs.nfC15100,
      avertissement: AppConstants.disclaimerText,
    );
  }

  static CalculResult calibreDisjoncteur({
    required double puissanceW,
    required double tensionV,
    double facteurPuissance = 0.8,
  }) {
    if (puissanceW <= 0) {
      throw ArgumentError('La puissance doit être > 0.');
    }
    if (tensionV != 230 && tensionV != 400) {
      throw ArgumentError('Tension nominale : 230 V ou 400 V.');
    }
    final intensite = puissanceW / (tensionV * facteurPuissance);
    final calibre = calibresNormalises.firstWhere(
      (c) => c >= intensite,
      orElse: () => calibresNormalises.last,
    );
    return CalculResult(
      valeurPrincipale: calibre.toDouble(),
      unite: 'A',
      designation: 'Calibre disjoncteur',
      details: {
        'intensite_calculee': intensite,
        'tension_V': tensionV,
      },
      referenceNormative: NormativeRefs.nfC15100,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Prescriptions indicatives NF C 15-100 par type de pièce.
  static CalculResult pointsLumineux({
    required String typePiece,
    required double surfaceM2,
  }) {
    if (surfaceM2 <= 0) {
      throw ArgumentError('La surface doit être > 0.');
    }
    final (pointsLumineux, prises) = switch (typePiece) {
      'sejour' || 'salon' => (
          (surfaceM2 / 10).ceil().clamp(1, 20),
          (surfaceM2 / 4).ceil().clamp(5, 20),
        ),
      'chambre' => (1, 3),
      'cuisine' => (2, 6),
      'salle_de_bain' => (1, 1),
      'wc' => (1, 1),
      'couloir' => (1, 1),
      _ => ((surfaceM2 / 12).ceil().clamp(1, 10), 2),
    };
    return CalculResult(
      valeurPrincipale: pointsLumineux.toDouble(),
      unite: 'points lumineux',
      designation: 'Éclairage / prises — $typePiece',
      details: {
        'points_lumineux': pointsLumineux.toDouble(),
        'prises': prises.toDouble(),
        'type_piece': typePiece,
        'surface_m2': surfaceM2,
      },
      referenceNormative: NormativeRefs.nfC15100,
      avertissement: AppConstants.disclaimerText,
    );
  }
}
