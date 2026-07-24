# Document de Design Technique — btp-calcul-app

## Vue d'ensemble

L'application **btp-calcul-app** est une application Flutter multiplateforme (Android, iOS, Windows, Linux, macOS) de calculs de quantitatifs BTP et de génération de devis. Elle suit une architecture client-serveur : un client Flutter communique avec un backend Django REST via HTTPS. Le client embarque un moteur de calcul local (Dart) pour garantir les performances hors-ligne, et délègue au backend les opérations nécessitant un traitement lourd (analyse IA des plans, synchronisation multi-appareils, authentification).

---

## Architecture Globale

```
┌──────────────────────────────────────────────────────────┐
│                  APPLICATION FLUTTER                       │
│                                                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Présentation│  │   Domaine    │  │     Données     │  │
│  │  (Widgets)  │◄─│  (Providers  │◄─│ (Repositories,  │  │
│  │  (Screens)  │  │   Riverpod)  │  │  Drift, HTTP)   │  │
│  └─────────────┘  └──────────────┘  └─────────────────┘  │
│                                             │              │
│                          ┌──────────────────┘              │
│                          │  Drift (SQLite local)           │
└──────────────────────────┼─────────────────────────────────┘
                           │ HTTPS / REST (JWT)
┌──────────────────────────┼─────────────────────────────────┐
│              BACKEND DJANGO                │               │
│  ┌──────────────────┐  ┌─┴──────────────┐ │               │
│  │ Django REST API  │  │ Moteur calcul  │ │               │
│  │  (Views, Auth)   │  │   (Python)     │ │               │
│  └──────────────────┘  └────────────────┘ │               │
│  ┌──────────────────┐  ┌────────────────┐  │               │
│  │  Module IA       │  │  PostgreSQL    │  │               │
│  │ (API Claude)     │  │  (Base données)│  │               │
│  └──────────────────┘  └────────────────┘  │               │
└────────────────────────────────────────────┘
```

---

## Structure du Projet Flutter

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, routage, providers globaux
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Palette WCAG 2.1 AA (contraste ≥ 4.5:1)
│   │   ├── app_typography.dart     # Tailles polices (≥ 16sp résultats)
│   │   └── normative_refs.dart     # Références DTU, BAEL, NF C 15-100
│   ├── errors/
│   │   ├── failures.dart           # Classes d'erreurs domaine
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── api_client.dart         # Client HTTP avec intercepteur JWT
│   │   └── connectivity_service.dart
│   └── utils/
│       ├── number_formatter.dart   # Formatage selon locale (FCFA/EUR)
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository_impl.dart
│   │   │   └── secure_token_storage.dart  # flutter_secure_storage
│   │   ├── domain/
│   │   │   ├── auth_repository.dart
│   │   │   └── models/user_model.dart
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart
│   │       └── screens/login_screen.dart
│   ├── calcul/
│   │   ├── data/
│   │   │   └── calcul_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── calcul_repository.dart
│   │   │   ├── moteur/
│   │   │   │   ├── terrassement_engine.dart
│   │   │   │   ├── gros_oeuvre_engine.dart
│   │   │   │   ├── cloisons_engine.dart
│   │   │   │   ├── finitions_engine.dart
│   │   │   │   └── electricite_engine.dart
│   │   │   └── models/
│   │   │       ├── calcul_result.dart
│   │   │       ├── type_sol.dart
│   │   │       └── ratio_ferraillage.dart
│   │   └── presentation/
│   │       ├── providers/calcul_providers.dart
│   │       └── screens/
│   ├── devis/
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       ├── devis.dart
│   │   │       ├── ligne_devis.dart
│   │   │       └── materiau.dart
│   │   └── presentation/
│   ├── plan/
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       ├── plan.dart
│   │   │       └── element_plan.dart
│   │   └── presentation/
│   │       └── widgets/plan_painter.dart  # CustomPainter
│   ├── projet/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       └── presentation/
│           └── screens/settings_screen.dart
└── shared/
    ├── database/
    │   ├── app_database.dart       # Drift database
    │   ├── tables/                 # Tables Drift
    │   └── sync_journal.dart       # Journal de modifications
    └── widgets/
        ├── disclaimer_banner.dart  # Avertissement responsabilité
        └── normative_badge.dart    # Badge référence normative
```

---

## Moteur de Calcul

Le moteur de calcul est implémenté en double couche :
- **Côté Flutter (Dart)** : calculs synchrones, résultat < 200 ms, disponibles hors-ligne.
- **Côté Backend (Python)** : version serveur identique utilisée lors de la synchronisation pour vérification de cohérence.

### 2.1 Terrassement (Dart)

```dart
// lib/features/calcul/domain/moteur/terrassement_engine.dart

class TerrassementEngine {
  static const _normRef = 'DTU 12.1';

  /// Calcule le volume de déblais (m³).
  static CalculResult deblai({
    required double longueur,
    required double largeur,
    required double profondeur,
    required TypeSol typeSol,
  }) {
    assert(longueur > 0 && largeur > 0 && profondeur > 0);
    final volumeEnPlace = longueur * largeur * profondeur;
    final volumeFoisonne = volumeEnPlace * typeSol.coefficientFoisonnement;
    return CalculResult(
      valeurPrincipale: volumeFoisonne,
      unite: 'm³',
      details: {
        'volume_en_place': volumeEnPlace,
        'coefficient_foisonnement': typeSol.coefficientFoisonnement,
        'type_sol': typeSol.libelle,
      },
      referenceNormative: _normRef,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Calcule le volume de remblais (m³).
  static CalculResult remblai({
    required double longueur,
    required double largeur,
    required double hauteur,
    required TypeSol typeSol,
  }) {
    assert(longueur > 0 && largeur > 0 && hauteur > 0);
    final volumeEnPlace = longueur * largeur * hauteur;
    final volumeFoisonne = volumeEnPlace * typeSol.coefficientFoisonnement;
    return CalculResult(
      valeurPrincipale: volumeFoisonne,
      unite: 'm³',
      details: {
        'volume_en_place': volumeEnPlace,
        'coefficient_foisonnement': typeSol.coefficientFoisonnement,
        'type_sol': typeSol.libelle,
      },
      referenceNormative: _normRef,
      avertissement: AppConstants.disclaimerText,
    );
  }
}

class TypeSol {
  final String libelle;
  final double coefficientFoisonnement; // [1.0, 2.0]
  const TypeSol({required this.libelle, required this.coefficientFoisonnement});

  static const terreVegetale = TypeSol(libelle: 'Terre végétale', coefficientFoisonnement: 1.25);
  static const argile       = TypeSol(libelle: 'Argile',          coefficientFoisonnement: 1.30);
  static const sable        = TypeSol(libelle: 'Sable',           coefficientFoisonnement: 1.10);
  static const roche        = TypeSol(libelle: 'Roche',           coefficientFoisonnement: 1.50);

  static const List<TypeSol> defaults = [terreVegetale, argile, sable, roche];
}
```

### 2.2 Gros Œuvre (Dart)

```dart
// lib/features/calcul/domain/moteur/gros_oeuvre_engine.dart

class GrosOeuvreEngine {
  static const _normRefDTU   = 'DTU 21';
  static const _normRefBAEL  = 'BAEL 91 rev. 99 / Eurocode 2';

  static const double _densiteAcier = 7850.0; // kg/m³
  static const double _epaisseurJointMm = 10.0; // mm

  /// Volume béton d'une dalle (m³), avec coefficient de perte.
  static CalculResult volumeBeton({
    required double longueur,
    required double largeur,
    required double epaisseur,
    double coefficientPerte = 0.03, // [0.01, 0.10]
  }) {
    final volumeNet = longueur * largeur * epaisseur;
    final volumeAvecPerte = volumeNet * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: volumeAvecPerte,
      unite: 'm³',
      details: {
        'volume_net': volumeNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: '$_normRefDTU, $_normRefBAEL',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Nombre de parpaings, avec coefficient de perte.
  static CalculResult nombreParpaings({
    required double longueurMur,
    required double hauteurMur,
    required double longueurParpaing, // m
    required double hauteurParpaing,  // m
    double coefficientPerte = 0.05,   // [0.01, 0.20]
  }) {
    final surfaceMur = longueurMur * hauteurMur;
    final surfaceParpaing = longueurParpaing * hauteurParpaing;
    final nbNet = surfaceMur / surfaceParpaing;
    final nbAvecPerte = (nbNet * (1 + coefficientPerte)).ceil();
    return CalculResult(
      valeurPrincipale: nbAvecPerte.toDouble(),
      unite: 'unités',
      details: {
        'surface_mur': surfaceMur,
        'surface_parpaing': surfaceParpaing,
        'nb_net': nbNet,
        'coefficient_perte': coefficientPerte,
      },
      referenceNormative: _normRefDTU,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Quantité acier en kg selon ratio ferraillage.
  static CalculResult quantiteAcier({
    required double volumeBeton, // m³
    required RatioFerraillage ratio,
  }) {
    final masseAcier = volumeBeton * ratio.valeurKgM3;
    return CalculResult(
      valeurPrincipale: masseAcier,
      unite: 'kg',
      details: {
        'volume_beton': volumeBeton,
        'ratio_kg_m3': ratio.valeurKgM3,
        'element': ratio.typeElement,
      },
      referenceNormative: '$_normRefBAEL — ${ratio.sourceNormative}',
      avertissement: AppConstants.disclaimerText,
    );
  }
}
```

### 2.3 Cloisons, Doublages et Plafonds (Dart)

```dart
// lib/features/calcul/domain/moteur/cloisons_engine.dart

class CloisonsEngine {
  /// Surface cloisons (m²) = périmètre × hauteur, avec coefficient de perte.
  static CalculResult surfaceCloison({
    required double longueurPiece,
    required double largeurPiece,
    required double hauteurPiece,
    double coefficientPerte = 0.10, // [0.01, 0.20]
  }) {
    final perimeter = 2 * (longueurPiece + largeurPiece);
    final surfaceNette = perimeter * hauteurPiece;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      details: {'surface_nette': surfaceNette, 'perimetre': perimeter},
      referenceNormative: 'DTU 25.41',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Surface plafond (m²) = longueur × largeur, avec coefficient de perte.
  static CalculResult surfacePlafond({
    required double longueur,
    required double largeur,
    double coefficientPerte = 0.10,
  }) {
    final surfaceNette = longueur * largeur;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      details: {'surface_nette': surfaceNette},
      referenceNormative: 'DTU 58.1',
      avertissement: AppConstants.disclaimerText,
    );
  }
}
```

### 2.4 Finitions (Dart)

```dart
// lib/features/calcul/domain/moteur/finitions_engine.dart

class FinitionsEngine {
  /// Surface à peindre (m²), déduction des ouvertures.
  static CalculResult surfacePeinture({
    required double longueur,
    required double largeur,
    required double hauteur,
    required List<Ouverture> ouvertures,
    double coefficientPerte = 0.10,
  }) {
    final surfaceTotale = 2 * (longueur + largeur) * hauteur
        + longueur * largeur; // murs + plafond
    final deductionOuvertures = ouvertures.fold(0.0, (s, o) => s + o.surface);
    final surfaceNette = surfaceTotale - deductionOuvertures;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      details: {
        'surface_totale': surfaceTotale,
        'deduction_ouvertures': deductionOuvertures,
        'surface_nette': surfaceNette,
      },
      referenceNormative: 'DTU 59.1',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Nombre de rouleaux de papier peint.
  static CalculResult nombreRouleaux({
    required double surfaceATapisser,
    required double hauteurRouleau,
    required double laize,
    double coefficientPerte = 0.10,
  }) {
    final surfaceRouleau = hauteurRouleau * laize;
    final nb = (surfaceATapisser * (1 + coefficientPerte) / surfaceRouleau).ceil();
    return CalculResult(
      valeurPrincipale: nb.toDouble(),
      unite: 'rouleaux',
      details: {'surface_rouleau': surfaceRouleau},
      referenceNormative: 'DTU 59.4',
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Surface de carrelage avec coefficient de perte.
  static CalculResult surfaceCarrelage({
    required double longueur,
    required double largeur,
    double coefficientPerte = 0.10,
  }) {
    final surfaceNette = longueur * largeur;
    final surfaceAvecPerte = surfaceNette * (1 + coefficientPerte);
    return CalculResult(
      valeurPrincipale: surfaceAvecPerte,
      unite: 'm²',
      details: {'surface_nette': surfaceNette},
      referenceNormative: 'DTU 52.1',
      avertissement: AppConstants.disclaimerText,
    );
  }
}

class Ouverture {
  final double largeur;
  final double hauteur;
  double get surface => largeur * hauteur;
  const Ouverture({required this.largeur, required this.hauteur});
}
```

### 2.5 Électricité NF C 15-100 (Dart)

```dart
// lib/features/calcul/domain/moteur/electricite_engine.dart

/// Sections câbles normalisées (mm²) selon NF C 15-100.
const List<double> _sectionsNormalisees = [1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0];

/// Calibres disjoncteurs normalisés (A) selon NF C 15-100.
const List<int> _calibresNormalises = [10, 16, 20, 25, 32, 40, 63];

class ElectriciteEngine {
  static const _normRef = 'NF C 15-100';

  /// Bilan puissance totale (W).
  static CalculResult bilanPuissance({required List<Circuit> circuits}) {
    final puissanceTotale = circuits.fold(0.0, (s, c) => s + c.puissanceW);
    return CalculResult(
      valeurPrincipale: puissanceTotale,
      unite: 'W',
      details: {'nb_circuits': circuits.length.toDouble()},
      referenceNormative: _normRef,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Section minimale de câble (mm²) par chute de tension admissible (3%).
  /// Formule : S = (ρ × L × I) / (ΔU_max × U_n)
  /// ρ_cuivre = 0.0225 Ω·mm²/m, ρ_aluminium = 0.036 Ω·mm²/m
  static CalculResult sectionCable({
    required double puissanceW,
    required double longueurM,
    required double tensionV,        // 230 ou 400
    required bool estCuivre,
    double facteurPuissance = 0.8,
    double chuteAdmissible = 0.03,   // 3%
  }) {
    final rho = estCuivre ? 0.0225 : 0.036;
    final intensite = puissanceW / (tensionV * facteurPuissance);
    final chuteMax = chuteAdmissible * tensionV;
    final sectionCalc = (2 * rho * longueurM * intensite) / chuteMax;
    final sectionNorm = _sectionsNormalisees.firstWhere(
      (s) => s >= sectionCalc,
      orElse: () => _sectionsNormalisees.last,
    );
    return CalculResult(
      valeurPrincipale: sectionNorm,
      unite: 'mm²',
      details: {
        'section_calculee': sectionCalc,
        'intensite_A': intensite,
        'conducteur': estCuivre ? 'cuivre' : 'aluminium',
      },
      referenceNormative: _normRef,
      avertissement: AppConstants.disclaimerText,
    );
  }

  /// Calibre minimal disjoncteur (A).
  static CalculResult calibreDisjoncteur({
    required double puissanceW,
    required double tensionV,
    double facteurPuissance = 0.8,
  }) {
    final intensite = puissanceW / (tensionV * facteurPuissance);
    final calibre = _calibresNormalises.firstWhere(
      (c) => c >= intensite,
      orElse: () => _calibresNormalises.last,
    );
    return CalculResult(
      valeurPrincipale: calibre.toDouble(),
      unite: 'A',
      details: {'intensite_calculee': intensite},
      referenceNormative: _normRef,
      avertissement: AppConstants.disclaimerText,
    );
  }
}

class Circuit {
  final String designation;
  final double puissanceW;
  final double longueurM;
  const Circuit({required this.designation, required this.puissanceW, required this.longueurM});
}
```

---

## Modèle de Données

### 3.1 Tables Drift (SQLite local)

```dart
// lib/shared/database/tables/

// ── Utilisateurs ──────────────────────────────────────────
class Utilisateurs extends Table {
  TextColumn get id            => text().withLength(min: 36, max: 36)();  // UUID
  TextColumn get email         => text().withLength(max: 255)();
  TextColumn get nomAffichage  => text().withLength(max: 100)();
  BoolColumn get estAbonne     => boolean().withDefault(const Constant(false))();
  DateTimeColumn get abonnementExpiration => dateTime().nullable()();
  BoolColumn get cguAcceptees  => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cguDateAcceptation   => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Projets ───────────────────────────────────────────────
class Projets extends Table {
  TextColumn get id             => text().withLength(min: 36, max: 36)();
  TextColumn get utilisateurId  => text().references(Utilisateurs, #id)();
  TextColumn get nom            => text().withLength(max: 200)();
  TextColumn get adresseChantier => text().nullable()();
  TextColumn get nomClient      => text().nullable()();
  TextColumn get deviseCode     => text().withLength(max: 3)(); // 'XOF' ou 'EUR'
  BoolColumn get estSynchro     => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt  => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt  => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Calculs ───────────────────────────────────────────────
class Calculs extends Table {
  TextColumn get id           => text().withLength(min: 36, max: 36)();
  TextColumn get projetId     => text().references(Projets, #id)();
  TextColumn get typeCalcul   => text()(); // 'terrassement'|'gros_oeuvre'|'cloison'|'finition'|'electricite'
  TextColumn get phase        => text()(); // 'terrassement'|'fondation'|'gros_oeuvre'|'finition'
  TextColumn get parametresJson => text()(); // JSON des entrées
  TextColumn get resultatsJson  => text()(); // JSON du CalculResult
  TextColumn get referenceNormative => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Devis ─────────────────────────────────────────────────
class Devis extends Table {
  TextColumn get id          => text().withLength(min: 36, max: 36)();
  TextColumn get projetId    => text().references(Projets, #id)();
  TextColumn get intitule    => text().withLength(max: 200)();
  DateTimeColumn get dateDevis => dateTime()();
  TextColumn get deviseCode  => text().withLength(max: 3)();
  RealColumn get tauxConversion => real().withDefault(const Constant(1.0))();
  BoolColumn get estSynchro  => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Lignes Devis ──────────────────────────────────────────
class LignesDevis extends Table {
  TextColumn get id           => text().withLength(min: 36, max: 36)();
  TextColumn get devisId      => text().references(Devis, #id)();
  TextColumn get designation  => text().withLength(max: 300)();
  TextColumn get phase        => text()();
  RealColumn get quantite     => real()();
  TextColumn get unite        => text().withLength(max: 20)();
  RealColumn get prixUnitaire => real()();
  RealColumn get coefficientPerte => real().withDefault(const Constant(0.0))();
  IntColumn  get ordre        => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Matériaux ─────────────────────────────────────────────
class Materiaux extends Table {
  TextColumn get id           => text().withLength(min: 36, max: 36)();
  TextColumn get designation  => text().withLength(max: 200)();
  TextColumn get unite        => text().withLength(max: 20)();
  RealColumn get prixFCFA     => real().withDefault(const Constant(0.0))();
  RealColumn get prixEUR      => real().withDefault(const Constant(0.0))();
  BoolColumn get estPersonnalise => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// ── Plans ─────────────────────────────────────────────────
class Plans extends Table {
  TextColumn get id            => text().withLength(min: 36, max: 36)();
  TextColumn get projetId      => text().references(Projets, #id)();
  TextColumn get phase         => text()(); // 'terrassement'|'fondation'|'gros_oeuvre'|'finition'
  TextColumn get cheminImage   => text()();
  RealColumn get echelleMetresParPixel => real().nullable()(); // après étalonnage
  BoolColumn get etalonneValide => boolean().withDefault(const Constant(false))();
  BoolColumn get analyseIaDone  => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt  => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Éléments Plan ─────────────────────────────────────────
class ElementsPlan extends Table {
  TextColumn get id         => text().withLength(min: 36, max: 36)();
  TextColumn get planId     => text().references(Plans, #id)();
  TextColumn get typeElement => text()(); // 'mur'|'ouverture'|'cote'|'surface'
  TextColumn get geometrieJson => text()(); // JSON {x1,y1,x2,y2,…}
  RealColumn get valeurMetres => real().nullable()(); // après étalonnage
  TextColumn get label      => text().nullable()();
  IntColumn  get ordre      => integer()();
  BoolColumn get estValide  => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Journal de synchronisation ────────────────────────────
class JournalSync extends Table {
  IntColumn  get id           => integer().autoIncrement()();
  TextColumn get entiteType   => text()(); // 'Projet'|'Devis'|…
  TextColumn get entiteId     => text()();
  TextColumn get operation    => text()(); // 'INSERT'|'UPDATE'|'DELETE'
  TextColumn get payloadJson  => text()();
  BoolColumn get estSynchro   => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Types Sol ─────────────────────────────────────────────
class TypesSol extends Table {
  TextColumn get id                     => text().withLength(min: 36, max: 36)();
  TextColumn get libelle                => text().withLength(max: 100)();
  RealColumn get coefficientFoisonnement => real()(); // [1.0, 2.0]
  BoolColumn get estDefaut              => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Ratios Ferraillage ────────────────────────────────────
class RatiosFerraillage extends Table {
  TextColumn get id               => text().withLength(min: 36, max: 36)();
  TextColumn get typeElement      => text()(); // 'fondation'|'poteau'|'poutre'|'dalle'
  RealColumn get valeurKgM3       => real()();
  TextColumn get sourceNormative  => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3.2 Modèles Django (PostgreSQL)

```python
# backend/calcul_btp/models.py
import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser

class Utilisateur(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    est_abonne = models.BooleanField(default=False)
    abonnement_expiration = models.DateTimeField(null=True, blank=True)
    cgu_acceptees = models.BooleanField(default=False)
    cgu_date_acceptation = models.DateTimeField(null=True, blank=True)

class Projet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='projets')
    nom = models.CharField(max_length=200)
    adresse_chantier = models.TextField(blank=True)
    nom_client = models.CharField(max_length=200, blank=True)
    devise_code = models.CharField(max_length=3, default='XOF')  # 'XOF' | 'EUR'
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class Calcul(models.Model):
    TYPE_CHOICES = [
        ('terrassement', 'Terrassement'),
        ('gros_oeuvre',  'Gros Œuvre'),
        ('cloison',      'Cloison'),
        ('finition',     'Finition'),
        ('electricite',  'Électricité'),
    ]
    PHASE_CHOICES = [
        ('terrassement', 'Terrassement'),
        ('fondation',    'Fondation'),
        ('gros_oeuvre',  'Gros Œuvre'),
        ('finition',     'Finition'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name='calculs')
    type_calcul = models.CharField(max_length=30, choices=TYPE_CHOICES)
    phase = models.CharField(max_length=30, choices=PHASE_CHOICES)
    parametres = models.JSONField()
    resultats = models.JSONField()
    reference_normative = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

```python
class Devis(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name='devis')
    intitule = models.CharField(max_length=200)
    date_devis = models.DateField()
    devise_code = models.CharField(max_length=3)
    taux_conversion = models.DecimalField(max_digits=12, decimal_places=4, default=1)
    created_at = models.DateTimeField(auto_now_add=True)

class LigneDevis(models.Model):
    PHASE_CHOICES = Calcul.PHASE_CHOICES
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    devis = models.ForeignKey(Devis, on_delete=models.CASCADE, related_name='lignes')
    designation = models.CharField(max_length=300)
    phase = models.CharField(max_length=30, choices=PHASE_CHOICES)
    quantite = models.DecimalField(max_digits=14, decimal_places=4)
    unite = models.CharField(max_length=20)
    prix_unitaire = models.DecimalField(max_digits=14, decimal_places=2)
    coefficient_perte = models.DecimalField(max_digits=5, decimal_places=4, default=0)
    ordre = models.PositiveIntegerField()

    @property
    def total(self):
        return self.quantite * self.prix_unitaire

class Plan(models.Model):
    PHASE_CHOICES = Calcul.PHASE_CHOICES
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name='plans')
    phase = models.CharField(max_length=30, choices=PHASE_CHOICES)
    image_url = models.URLField()
    echelle_metres_par_pixel = models.FloatField(null=True, blank=True)
    etalonnage_valide = models.BooleanField(default=False)
    analyse_ia_done = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

class ElementPlan(models.Model):
    TYPE_CHOICES = [
        ('mur', 'Mur'), ('ouverture', 'Ouverture'),
        ('cote', 'Cote'), ('surface', 'Surface'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(Plan, on_delete=models.CASCADE, related_name='elements')
    type_element = models.CharField(max_length=20, choices=TYPE_CHOICES)
    geometrie = models.JSONField()  # {x1, y1, x2, y2, ...}
    valeur_metres = models.FloatField(null=True, blank=True)
    label = models.CharField(max_length=100, blank=True)
    ordre = models.PositiveIntegerField()
    est_valide = models.BooleanField(default=True)
```

---

## API REST

### 4.1 Endpoints principaux

| Méthode | Endpoint                              | Auth     | Description                               |
|---------|---------------------------------------|----------|-------------------------------------------|
| POST    | `/api/auth/register/`                 | —        | Création de compte                        |
| POST    | `/api/auth/login/`                    | —        | Connexion → JWT access + refresh          |
| POST    | `/api/auth/token/refresh/`            | —        | Rafraîchissement JWT                      |
| POST    | `/api/auth/logout/`                   | Bearer   | Invalidation session                      |
| GET     | `/api/projets/`                       | Bearer   | Liste projets utilisateur                 |
| POST    | `/api/projets/`                       | Bearer   | Créer un projet                           |
| GET     | `/api/projets/{id}/`                  | Bearer   | Détail projet                             |
| PUT     | `/api/projets/{id}/`                  | Bearer   | Modifier projet                           |
| DELETE  | `/api/projets/{id}/`                  | Bearer   | Supprimer projet                          |
| GET     | `/api/projets/{id}/calculs/`          | Bearer   | Calculs d'un projet                       |
| POST    | `/api/projets/{id}/calculs/`          | Bearer   | Sauvegarder un calcul                     |
| GET     | `/api/projets/{id}/devis/`            | Bearer   | Devis d'un projet                         |
| POST    | `/api/projets/{id}/devis/`            | Bearer   | Créer un devis                            |
| GET     | `/api/devis/{id}/`                    | Bearer   | Détail devis avec lignes                  |
| POST    | `/api/devis/{id}/export/pdf/`         | Bearer+Abonné | Export PDF                          |
| POST    | `/api/devis/{id}/export/excel/`       | Bearer+Abonné | Export Excel                        |
| POST    | `/api/plans/analyse/`                 | Bearer+Abonné | Analyse IA d'un plan              |
| POST    | `/api/sync/journal/`                  | Bearer   | Synchronisation journal local             |
| GET     | `/api/materiaux/`                     | Bearer   | Base de prix matériaux                    |
| GET     | `/api/referentiels/`                  | —        | TypesSol, RatiosFerraillage (publics)     |

### 4.2 Format de réponse standard

```json
// Succès
{
  "status": "success",
  "data": { ... },
  "meta": { "timestamp": "2024-01-15T10:00:00Z" }
}

// Erreur
{
  "status": "error",
  "code": "ABONNEMENT_REQUIS",
  "message": "Cette fonctionnalité nécessite un abonnement actif.",
  "http_status": 403
}
```

### 4.3 Codes d'erreur métier

| Code                      | HTTP | Signification                                    |
|---------------------------|------|--------------------------------------------------|
| `ABONNEMENT_REQUIS`       | 403  | Fonctionnalité réservée aux abonnés              |
| `TOKEN_INVALIDE`          | 401  | JWT invalide ou expiré                           |
| `IDENTIFIANTS_INCORRECTS` | 401  | Connexion échouée (message générique)            |
| `VALIDATION_ERREUR`       | 400  | Données entrantes invalides                      |
| `ANALYSE_IA_ERREUR`       | 502  | Échec d'analyse par le module IA                 |
| `CONFLIT_SYNC`            | 409  | Conflit de synchronisation détecté               |

---

## Gestion d'État Riverpod

```dart
// lib/features/calcul/presentation/providers/calcul_providers.dart

// Provider du résultat de terrassement
final terrassementResultProvider = StateNotifierProvider<
    TerrassementNotifier, AsyncValue<CalculResult?>>((ref) {
  return TerrassementNotifier();
});

class TerrassementNotifier extends StateNotifier<AsyncValue<CalculResult?>> {
  TerrassementNotifier() : super(const AsyncValue.data(null));

  void calculer({
    required double longueur,
    required double largeur,
    required double profondeur,
    required TypeSol typeSol,
  }) {
    state = const AsyncValue.loading();
    try {
      final result = TerrassementEngine.deblai(
        longueur: longueur, largeur: largeur,
        profondeur: profondeur, typeSol: typeSol,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider de connectivité
final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

// Provider d'authentification
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
```

---

## Module Plan par Image

### 6.1 Pipeline complet

```
Image (galerie/caméra)
  │
  ▼ image_picker
Stockage local (chemin)
  │
  ▼ Saisie mesure de référence (UI)
Étalonnage (pixels → mètres)
  │
  ▼ POST /api/plans/analyse/ {image_base64, mesure_ref_metres, mesure_ref_pixels}
Backend Module IA
  │  ├─ Encodage image en base64
  │  ├─ Appel API Claude (multimodal) : prompt structuré → JSON
  │  └─ Validation et normalisation JSON
  │
  ▼ Retour JSON {segments: [{type, x1,y1,x2,y2, cote_metres?}]}
CustomPainter (rendu superposé)
  │
  ▼ Correction manuelle (drag, add, delete)
  │
  ▼ Validation utilisateur
  │
  ▼ Extraction dimensions → alimenter Moteur de calcul (Phase correspondante)
```

### 6.2 Format JSON retourné par le Module IA

```json
{
  "segments": [
    {
      "type": "mur",
      "x1": 120, "y1": 80,
      "x2": 450, "y2": 80,
      "valeur_metres": 4.2,
      "label": "Mur Nord"
    },
    {
      "type": "ouverture",
      "x1": 220, "y1": 80,
      "x2": 310, "y2": 80,
      "valeur_metres": 0.9,
      "label": "Porte"
    }
  ],
  "echelle_metres_par_pixel": 0.0133,
  "confiance": 0.87
}
```

### 6.3 CustomPainter

```dart
// lib/features/plan/presentation/widgets/plan_painter.dart

class PlanPainter extends CustomPainter {
  final List<ElementPlan> elements;
  final ElementPlan? elementSelectionne;
  final double echelleMetresParPixel;

  PlanPainter({
    required this.elements,
    this.elementSelectionne,
    required this.echelleMetresParPixel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final el in elements) {
      if (!el.estValide) continue;
      final paint = Paint()
        ..color = _couleurParType(el.typeElement)
        ..strokeWidth = el == elementSelectionne ? 3.0 : 1.5
        ..style = PaintingStyle.stroke;
      final geo = el.geometrie as Map<String, dynamic>;
      canvas.drawLine(
        Offset(geo['x1'] as double, geo['y1'] as double),
        Offset(geo['x2'] as double, geo['y2'] as double),
        paint,
      );
      if (el.label != null) {
        // Afficher le label à mi-segment
        _drawLabel(canvas, el, geo);
      }
    }
  }

  Color _couleurParType(String type) {
    switch (type) {
      case 'mur':       return Colors.blue;
      case 'ouverture': return Colors.orange;
      case 'cote':      return Colors.green;
      default:          return Colors.grey;
    }
  }

  void _drawLabel(Canvas canvas, ElementPlan el, Map geo) {
    final tp = TextPainter(
      text: TextSpan(
        text: el.label,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      ((geo['x1'] as double) + (geo['x2'] as double)) / 2,
      ((geo['y1'] as double) + (geo['y2'] as double)) / 2 - 14,
    ));
  }

  @override
  bool shouldRepaint(PlanPainter old) =>
      old.elements != elements || old.elementSelectionne != elementSelectionne;
}
```

---

## Module Devis

### 7.1 Calcul des totaux

```dart
// lib/features/devis/domain/models/devis.dart

class DevisModel {
  final String id;
  final String intitule;
  final DateTime dateDevis;
  final String deviseCode;
  final double tauxConversion;
  final List<LigneDevisModel> lignes;

  DevisModel({
    required this.id,
    required this.intitule,
    required this.dateDevis,
    required this.deviseCode,
    required this.tauxConversion,
    required this.lignes,
  });

  /// Lignes regroupées par phase.
  Map<String, List<LigneDevisModel>> get lignesParPhase =>
      lignes.fold({}, (map, l) {
        (map[l.phase] ??= []).add(l);
        return map;
      });

  /// Sous-total par phase.
  Map<String, double> get sousTotauxParPhase => lignesParPhase.map(
    (phase, ll) => MapEntry(phase, ll.fold(0.0, (s, l) => s + l.total)),
  );

  /// Total général.
  double get totalGeneral =>
      lignes.fold(0.0, (s, l) => s + l.total);

  /// Convertir dans une autre devise.
  DevisModel convertir(String nouvelleDevise, double nouveauTaux) {
    return DevisModel(
      id: id, intitule: intitule, dateDevis: dateDevis,
      deviseCode: nouvelleDevise, tauxConversion: nouveauTaux,
      lignes: lignes.map((l) => l.convertir(nouveauTaux / tauxConversion)).toList(),
    );
  }
}

class LigneDevisModel {
  final String id;
  final String designation;
  final String phase;
  final double quantite;
  final String unite;
  final double prixUnitaire;
  final double coefficientPerte;
  final int ordre;

  LigneDevisModel({
    required this.id, required this.designation, required this.phase,
    required this.quantite, required this.unite, required this.prixUnitaire,
    required this.coefficientPerte, required this.ordre,
  });

  double get total => quantite * prixUnitaire;

  LigneDevisModel convertir(double facteur) => LigneDevisModel(
    id: id, designation: designation, phase: phase,
    quantite: quantite, unite: unite, ordre: ordre,
    prixUnitaire: prixUnitaire * facteur,
    coefficientPerte: coefficientPerte,
  );
}
```

### 7.2 Export PDF (côté Flutter, Utilisateur abonné)

```dart
// lib/features/devis/domain/services/devis_export_service.dart

class DevisExportService {
  Future<Uint8List> exportPDF(DevisModel devis) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        _buildEntete(devis),
        _buildTableauLignes(devis),
        _buildTotauxParPhase(devis),
        _buildTotalGeneral(devis),
        _buildAvertissement(),
      ],
    ));
    return pdf.save();
  }

  Future<Uint8List> exportExcel(DevisModel devis) async {
    final excel = Excel.createExcel();
    final sheet = excel['Devis'];
    // En-têtes
    sheet.appendRow(['Désignation','Phase','Qté','Unité','P.U.','Total']);
    for (final l in devis.lignes) {
      sheet.appendRow([
        l.designation, l.phase, l.quantite, l.unite,
        l.prixUnitaire, l.total,
      ]);
    }
    // Formule Excel pour le total
    sheet.appendRow(['TOTAL', '', '', '', '',
      '=SUM(F2:F${devis.lignes.length + 1})']);
    return Uint8List.fromList(excel.encode()!);
  }
}
```

---

## Synchronisation Offline/Online

### 8.1 Journal de modifications (Drift)

```dart
// lib/shared/database/sync_journal.dart

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;

  SyncService(this._db, this._api);

  /// Enregistre une modification locale dans le journal.
  Future<void> enregistrer({
    required String entiteType,
    required String entiteId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.journalSync).insert(JournalSyncCompanion.insert(
      entiteType: entiteType,
      entiteId: entiteId,
      operation: operation,
      payloadJson: jsonEncode(payload),
    ));
  }

  /// Synchronise les entrées non encore envoyées, dans l'ordre de création.
  Future<SyncResult> synchroniser() async {
    final entrees = await (_db.select(_db.journalSync)
        ..where((t) => t.estSynchro.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    int succes = 0, conflits = 0, erreurs = 0;
    for (final entree in entrees) {
      try {
        final reponse = await _api.post('/api/sync/journal/', {
          'entite_type': entree.entiteType,
          'entite_id': entree.entiteId,
          'operation': entree.operation,
          'payload': jsonDecode(entree.payloadJson),
        });
        if (reponse.statusCode == 200) {
          await (_db.update(_db.journalSync)
              ..where((t) => t.id.equals(entree.id)))
              .write(JournalSyncCompanion(estSynchro: const Value(true)));
          succes++;
        } else if (reponse.statusCode == 409) {
          conflits++;
          // Notifier l'utilisateur via le ConflitProvider
        }
      } catch (_) {
        erreurs++;
      }
    }
    return SyncResult(succes: succes, conflits: conflits, erreurs: erreurs);
  }
}
```

### 8.2 Stratégie de réconciliation des conflits

En cas de conflit (HTTP 409), le système :
1. Conserve la version locale intacte dans le stockage Drift.
2. Stocke la version distante dans un champ `version_distante_json` du journal.
3. Déclenche le `ConflitProvider` Riverpod qui affiche une alerte à l'utilisateur.
4. L'utilisateur choisit "Conserver ma version" ou "Utiliser la version du serveur".
5. Le choix est appliqué localement et renvoyé au backend avec un flag `resolution: 'local'|'remote'`.

---

## Authentification JWT

### 9.1 Flow complet

```
Client Flutter                        Backend Django
     │                                      │
     │── POST /api/auth/login/ ────────────►│
     │   {email, password}                  │  Vérifie identifiants
     │                                      │  Génère JWT (access 1h + refresh 7j)
     │◄── 200 {access_token, refresh_token} ─│
     │                                      │
     │  flutter_secure_storage.write(       │
     │    'access_token', ...)              │
     │                                      │
     │── GET /api/projets/ ────────────────►│
     │   Authorization: Bearer <access>     │  Valide JWT
     │◄── 200 {data: [...]} ────────────────│
     │                                      │
     │  (access expirant dans < 5 min)      │
     │── POST /api/auth/token/refresh/ ────►│
     │   {refresh: <refresh_token>}         │  Vérifie refresh, émet nouveau access
     │◄── 200 {access_token} ──────────────│
     │                                      │
     │  (logout)                            │
     │── POST /api/auth/logout/ ───────────►│  Blackliste refresh token
     │◄── 204 No Content ──────────────────│
     │  secure_storage.delete('access')     │
     │  secure_storage.delete('refresh')    │
```

### 9.2 Intercepteur JWT (Dart)

```dart
// lib/core/network/api_client.dart

class JwtInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  JwtInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Tenter de rafraîchir
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final resp = await _dio.post('/api/auth/token/refresh/',
              data: {'refresh': refreshToken},
              options: Options(extra: {'noRetry': true}));
          final newAccess = resp.data['access_token'] as String;
          await _storage.write(key: 'access_token', value: newAccess);
          // Rejouer la requête originale
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retried = await _dio.fetch(err.requestOptions);
          handler.resolve(retried);
          return;
        } catch (_) {
          // Refresh invalide → rediriger vers login
          await _storage.deleteAll();
          // Naviguer vers l'écran de connexion via GoRouter
        }
      }
    }
    handler.next(err);
  }
}
```

---

## Contrôle d'Accès Freemium

### 10.1 Middleware Django

```python
# backend/calcul_btp/permissions.py
from rest_framework.permissions import BasePermission
from django.utils import timezone

class EstAbonne(BasePermission):
    """Vérifie que l'utilisateur dispose d'un abonnement actif."""
    message = "ABONNEMENT_REQUIS"

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if not request.user.est_abonne:
            return False
        if request.user.abonnement_expiration and \
           request.user.abonnement_expiration < timezone.now():
            return False
        return True
```

### 10.2 Garde Freemium côté Flutter

```dart
// lib/core/utils/freemium_guard.dart

class FreemiumGuard {
  static bool peutAcceder(AuthState auth, String fonctionnalite) {
    const fonctionnalitesAvancees = {
      'plan_image', 'export_pdf', 'export_excel',
      'synchronisation', 'devis_export',
    };
    if (!fonctionnalitesAvancees.contains(fonctionnalite)) return true;
    return auth.estConnecte && auth.estAbonne;
  }
}

// Utilisation dans un widget :
// if (!FreemiumGuard.peutAcceder(authState, 'export_pdf')) {
//   showDialog(context, builder: (_) => const InvitationAbonnementDialog());
//   return;
// }
```

---

## Conformité Normative

Les référentiels normatifs sont intégrés directement dans le moteur de calcul, pas comme données configurables :

| Norme           | Module                         | Intégration                                              |
|-----------------|-------------------------------|----------------------------------------------------------|
| DTU 12.1        | Terrassement                   | Formules de volume, types de sol, coefficients          |
| DTU 21          | Gros Œuvre (béton)             | Formules béton, tolérances, coefficients de perte       |
| BAEL 91 / EC2   | Ferraillage                    | Ratios kg/m³ par type d'élément structural              |
| DTU 25.41       | Cloisons plâtre                | Calcul surface, référence affichée dans résultat        |
| DTU 58.1        | Plafonds suspendus             | Calcul surface, référence affichée dans résultat        |
| DTU 59.1/59.4   | Peinture / Papier peint        | Coefficients de perte, références affichées             |
| DTU 52.1        | Carrelage                      | Coefficient de perte 10%, références affichées          |
| NF C 15-100     | Électricité                    | Sections câbles, calibres disjoncteurs, points lumineux |

Les références sont affichées systématiquement avec chaque résultat via le widget `NormativeBadge`.

```dart
// lib/shared/widgets/normative_badge.dart
class NormativeBadge extends StatelessWidget {
  final String reference;
  const NormativeBadge({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.verified_outlined, size: 16),
      label: Text(reference, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
```

---

## Gestion des Erreurs

| Source              | Type d'erreur                   | Traitement                                                        |
|---------------------|---------------------------------|-------------------------------------------------------------------|
| Moteur de calcul    | Paramètres invalides (≤ 0)      | `ArgumentError` attrapé → message UI clair, champ mis en évidence |
| API Backend         | 401 Token expiré                | Refresh automatique, puis re-login si échec                       |
| API Backend         | 403 Abonnement requis           | Dialog `InvitationAbonnementDialog`                               |
| API Backend         | 502 Erreur IA                   | Message d'erreur + option "Saisie manuelle"                       |
| API Backend         | 409 Conflit sync                | Dialog de résolution de conflit                                   |
| Réseau              | Pas de connexion                | Mode offline, bannière de notification, calculs locaux actifs     |
| Drift               | Erreur écriture SQLite          | Log + message "Impossible de sauvegarder, réessayez"              |

---

## Sécurité

- **HTTPS uniquement** : TLS 1.2 minimum, certificat validé. Connexion HTTP rejetée côté client.
- **JWT** : stocké exclusivement dans `flutter_secure_storage` (Keychain iOS, Keystore Android, Credential Locker Windows).
- **Clé API IA** : stockée dans les variables d'environnement du serveur Django (`python-decouple`), jamais exposée dans les réponses API.
- **Validation backend** : tous les champs sont validés via les serializers DRF avant traitement. Paramètres numériques vérifiés (> 0, dans les plages autorisées).
- **Mot de passe** : haché avec `argon2` (via `django-argon2`). Règle : ≥ 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre, vérifiée côté backend.
- **Message d'erreur générique** : en cas d'identifiants incorrects, le backend retourne toujours le même message sans distinguer l'email du mot de passe.
- **Assainissement des entrées** : `bleach` côté Django pour les champs texte libres.

---

## Performances

- **Moteur de calcul local** : toutes les opérations mathématiques sont synchrones et s'exécutent en Dart natif. Aucun appel réseau. Objectif < 200 ms garanti.
- **Sauvegarde automatique** : un `Timer.periodic(30s)` déclenche `_db.saveCurrentDraft()` lorsqu'un formulaire de calcul est actif.
- **Démarrage** : `main.dart` initialise Drift et les providers Riverpod de façon lazy. Les données critiques (profil utilisateur, liste projets) sont chargées en parallèle avec `Future.wait`.
- **CustomPainter** : `shouldRepaint` retourne `false` si la liste d'éléments est inchangée pour éviter les re-renders inutiles.

---

## Module Localisation et Devises

```dart
// lib/core/utils/number_formatter.dart

class NumberFormatter {
  static String formatMontant(double valeur, String deviseCode, Locale locale) {
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: deviseCode == 'XOF' ? 'FCFA' : '€',
      decimalDigits: deviseCode == 'XOF' ? 0 : 2,
    );
    return format.format(valeur);
  }

  static String formatQuantite(double valeur, Locale locale) {
    final format = NumberFormat.decimalPattern(locale.toString());
    return format.format(valeur);
  }
}
```

Toute l'interface est en français. Les clés de localisation (`AppLocalizations`) sont prévues pour une extension future vers l'anglais.

---

## Correctness Properties

*Une propriété est une caractéristique ou un comportement qui doit être vrai pour toutes les exécutions valides d'un système — essentiellement, une affirmation formelle sur ce que le système doit faire. Les propriétés servent de pont entre les spécifications lisibles par l'humain et les garanties de correction vérifiables automatiquement.*

### Property 1 : Formule de volume terrassement

*Pour tout* triplet de dimensions strictement positives (longueur, largeur, profondeur/hauteur) et tout type de sol avec coefficient de foisonnement `k`, le volume foisonné retourné par le moteur doit être égal à `longueur × largeur × profondeur × k`.

**Validates: Requirements 1.1, 1.2, 1.3**

---

### Property 2 : Cohérence du coefficient de foisonnement à la mise à jour

*Pour tout* volume en place calculé `V` et tout nouveau coefficient de foisonnement `k'` saisi par l'utilisateur, le volume recalculé doit être exactement `V × k'`, sans état résiduel du coefficient précédent.

**Validates: Requirements 1.6**

---

### Property 3 : Formule de volume béton avec perte

*Pour tout* triplet de dimensions (longueur, largeur, épaisseur) strictement positives et tout coefficient de perte `c` dans `[0.01, 0.10]`, le volume avec perte retourné doit être égal à `longueur × largeur × épaisseur × (1 + c)`.

**Validates: Requirements 2.1, 2.5**

---

### Property 4 : Nombre de parpaings avec perte borné

*Pour toute* surface de mur `S_mur > 0`, surface unitaire de parpaing `S_p > 0`, et coefficient de perte `c` dans `[0.01, 0.20]`, le nombre de parpaings retourné doit être supérieur ou égal à `ceil(S_mur / S_p)` et inférieur ou égal à `ceil(S_mur / S_p × 1.20)`, et ne doit jamais être inférieur au nombre sans perte.

**Validates: Requirements 2.2**

---

### Property 5 : Quantité d'acier proportionnelle au volume

*Pour tout* volume de béton `V > 0` et tout ratio de ferraillage `r > 0` (kg/m³), la masse d'acier retournée doit être exactement `V × r`. Doubler le volume doit doubler la masse d'acier.

**Validates: Requirements 2.4**

---

### Property 6 : Référence normative toujours présente dans les résultats

*Pour tout* calcul de n'importe quelle catégorie (terrassement, gros œuvre, cloison, finition, électricité) avec des paramètres valides, l'objet `CalculResult` retourné doit avoir un champ `referenceNormative` non vide, et l'avertissement de responsabilité ne doit pas être vide.

**Validates: Requirements 1.5, 2.7, 5.5, 6.1**

---

### Property 7 : Bilan de puissance électrique = somme des circuits

*Pour toute* liste de circuits électriques (possiblement vide ou très grande), le bilan de puissance retourné doit être exactement égal à la somme des puissances nominales de tous les circuits.

**Validates: Requirements 5.1**

---

### Property 8 : Section de câble normalisée ≥ section calculée

*Pour tout* circuit valide (puissance > 0, longueur > 0, tension ∈ {230, 400}), la section de câble normalisée retournée doit être la plus petite valeur dans `{1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0}` qui soit supérieure ou égale à la section théoriquement calculée.

**Validates: Requirements 5.2, 5.3**

---

### Property 9 : Invariant de cohérence des totaux de devis

*Pour tout* devis contenant n lignes, le total général doit être égal à la somme de tous les totaux de lignes, et également égal à la somme des sous-totaux par phase. Cette propriété doit tenir quel que soit le nombre de phases et la distribution des lignes.

**Validates: Requirements 7.2, 7.3**

---

### Property 10 : Conversion de devise préserve les proportions

*Pour tout* devis avec un taux de conversion `t1 → t2`, chaque montant converti doit être multiplié par le facteur `t2 / t1`, et le total général converti doit être égal à la somme des totaux de lignes convertis.

**Validates: Requirements 7.6, 12.3**

---

### Property 11 : Persistance locale round-trip

*Pour toute* entité créée dans le stockage Drift (Projet, Calcul, Devis, LigneDevis, Plan, ElementPlan, etc.), la relecture immédiate par identifiant doit retourner exactement les mêmes données que celles persistées, sans perte de champ ni altération de valeur.

**Validates: Requirements 15.1, 7.10, 9.3**

---

### Property 12 : Journal de synchronisation exhaustif

*Pour toute* séquence d'opérations locales (INSERT, UPDATE, DELETE) sur n'importe quelle entité synchronisable, chaque opération doit produire exactement une entrée non synchronisée dans le journal `JournalSync`, avec le type d'entité, l'identifiant et le payload corrects.

**Validates: Requirements 15.5**

---

### Property 13 : Contrôle d'accès freemium côté backend

*Pour tout* appel à une API de fonctionnalité avancée (analyse IA, export PDF/Excel, synchronisation) par un utilisateur sans abonnement actif ou avec abonnement expiré, la réponse doit être HTTP 403 avec le code `ABONNEMENT_REQUIS`.

**Validates: Requirements 11.5**

---

### Property 14 : Validation du mot de passe à la création de compte

*Pour tout* mot de passe ne respectant pas au moins une des règles suivantes — longueur ≥ 8, au moins une majuscule, au moins une minuscule, au moins un chiffre — l'API de création de compte doit retourner HTTP 400 avec une erreur de validation, sans créer le compte.

**Validates: Requirements 10.6**

---

### Property 15 : Surface à peindre = surface totale − déduction ouvertures

*Pour toutes* dimensions de pièce (longueur, largeur, hauteur) strictement positives et toute liste d'ouvertures (possiblement vide), la surface à peindre nette doit être égale à `surface_totale_parois − somme(surfaces_ouvertures)`, et doit toujours être ≥ 0.

**Validates: Requirements 4.1**

---

### Property 16 : Invariant de structure des éléments de plan

*Pour tout* plan associé à une phase définie, chaque `ElementPlan` qui lui est rattaché doit avoir un `type_element` appartenant à `{'mur', 'ouverture', 'cote', 'surface'}` et une géométrie JSON non nulle.

**Validates: Requirements 15.4, 8.8**

---

## Annexe — Moteur de Calcul Backend (Python)

Le moteur Python est une copie fonctionnelle du moteur Dart, utilisée pour valider la cohérence des calculs lors de la synchronisation et pour les tests unitaires serveur.

```python
# backend/calcul_btp/moteur/terrassement.py

from dataclasses import dataclass
from typing import Literal
import math

TypeSolLibelle = Literal['terre_vegetale', 'argile', 'sable', 'roche']

COEFFICIENTS_FOISONNEMENT: dict[TypeSolLibelle, float] = {
    'terre_vegetale': 1.25,
    'argile':         1.30,
    'sable':          1.10,
    'roche':          1.50,
}

@dataclass(frozen=True)
class ResultatCalcul:
    valeur_principale: float
    unite: str
    details: dict
    reference_normative: str
    avertissement: str = (
        "Résultats fournis à titre indicatif. "
        "Ne remplace pas l'intervention d'un professionnel qualifié."
    )

def calculer_deblai(
    longueur: float, largeur: float, profondeur: float,
    type_sol: TypeSolLibelle,
) -> ResultatCalcul:
    assert longueur > 0 and largeur > 0 and profondeur > 0
    coeff = COEFFICIENTS_FOISONNEMENT[type_sol]
    volume_en_place = longueur * largeur * profondeur
    volume_foisonne = volume_en_place * coeff
    return ResultatCalcul(
        valeur_principale=volume_foisonne,
        unite='m³',
        details={
            'volume_en_place': volume_en_place,
            'coefficient_foisonnement': coeff,
            'type_sol': type_sol,
        },
        reference_normative='DTU 12.1',
    )


# backend/calcul_btp/moteur/electricite.py

SECTIONS_NORMALISEES = [1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0]  # mm²
CALIBRES_NORMALISES  = [10, 16, 20, 25, 32, 40, 63]              # A
RHO = {'cuivre': 0.0225, 'aluminium': 0.036}  # Ω·mm²/m

def calculer_section_cable(
    puissance_w: float,
    longueur_m: float,
    tension_v: float,
    conducteur: Literal['cuivre', 'aluminium'],
    facteur_puissance: float = 0.8,
    chute_admissible: float = 0.03,
) -> ResultatCalcul:
    rho = RHO[conducteur]
    intensite = puissance_w / (tension_v * facteur_puissance)
    chute_max = chute_admissible * tension_v
    section_calc = (2 * rho * longueur_m * intensite) / chute_max
    section_norm = next(
        (s for s in SECTIONS_NORMALISEES if s >= section_calc),
        SECTIONS_NORMALISEES[-1],
    )
    return ResultatCalcul(
        valeur_principale=section_norm,
        unite='mm²',
        details={
            'section_calculee': section_calc,
            'intensite_A': intensite,
            'conducteur': conducteur,
        },
        reference_normative='NF C 15-100',
    )
```

---

*Document généré automatiquement dans le cadre du workflow Fast Task — Phase Design.*
