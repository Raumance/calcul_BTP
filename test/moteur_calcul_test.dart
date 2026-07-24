import 'package:flutter_test/flutter_test.dart';

import 'package:calcul_projet/features/calcul/domain/models/ratio_ferraillage.dart';
import 'package:calcul_projet/features/calcul/domain/models/type_sol.dart';
import 'package:calcul_projet/features/calcul/domain/moteur/electricite_engine.dart';
import 'package:calcul_projet/features/calcul/domain/moteur/gros_oeuvre_engine.dart';
import 'package:calcul_projet/features/calcul/domain/moteur/terrassement_engine.dart';
import 'package:calcul_projet/features/devis/domain/models/devis.dart';

void main() {
  group('TerrassementEngine', () {
    test('volume déblai = L×l×p×k', () {
      final r = TerrassementEngine.deblai(
        longueur: 10,
        largeur: 5,
        profondeur: 2,
        typeSol: TypeSol.argile,
      );
      expect(r.valeurPrincipale, closeTo(10 * 5 * 2 * 1.30, 1e-9));
      expect(r.referenceNormative, isNotEmpty);
      expect(r.avertissement, isNotEmpty);
    });
  });

  group('GrosOeuvreEngine', () {
    test('béton avec perte 3%', () {
      final r = GrosOeuvreEngine.volumeBeton(
        longueur: 4,
        largeur: 3,
        epaisseur: 0.15,
        coefficientPerte: 0.03,
      );
      expect(r.valeurPrincipale, closeTo(4 * 3 * 0.15 * 1.03, 1e-9));
    });

    test('acier proportionnel au volume', () {
      final r = GrosOeuvreEngine.quantiteAcier(
        volumeBeton: 2,
        ratio: RatioFerraillage.dalle,
      );
      expect(r.valeurPrincipale, 160);
    });
  });

  group('ElectriciteEngine', () {
    test('bilan = somme des circuits', () {
      final r = ElectriciteEngine.bilanPuissance(
        circuits: const [
          Circuit(designation: 'A', puissanceW: 1000, longueurM: 10),
          Circuit(designation: 'B', puissanceW: 500, longueurM: 5),
        ],
      );
      expect(r.valeurPrincipale, 1500);
    });

    test('section normalisée ≥ section calculée', () {
      final r = ElectriciteEngine.sectionCable(
        puissanceW: 3500,
        longueurM: 30,
        tensionV: 230,
        estCuivre: true,
      );
      final calc = r.details['section_calculee'] as double;
      expect(r.valeurPrincipale, greaterThanOrEqualTo(calc));
      expect(sectionsNormalisees, contains(r.valeurPrincipale));
    });
  });

  group('DevisModel', () {
    test('total = somme lignes = somme sous-totaux', () {
      final devis = DevisModel(
        id: '1',
        projetId: 'p',
        intitule: 'Test',
        dateDevis: DateTime(2026, 1, 1),
        deviseCode: 'XOF',
        tauxConversion: 1,
        lignes: const [
          LigneDevisModel(
            id: 'a',
            designation: 'Béton',
            phase: 'gros_oeuvre',
            quantite: 10,
            unite: 'm³',
            prixUnitaire: 100,
            coefficientPerte: 0.03,
            ordre: 1,
          ),
          LigneDevisModel(
            id: 'b',
            designation: 'Peinture',
            phase: 'finition',
            quantite: 50,
            unite: 'm²',
            prixUnitaire: 2,
            coefficientPerte: 0.1,
            ordre: 2,
          ),
        ],
      );
      expect(devis.totalGeneral, 1100);
      final sous = devis.sousTotauxParPhase.values.fold(0.0, (s, v) => s + v);
      expect(sous, devis.totalGeneral);
    });
  });
}
