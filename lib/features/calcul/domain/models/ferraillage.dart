import 'dart:math';

/// Types de section pour poteaux et poutres.
enum SectionType {
  carre,
  rectangulaire,
  circulaire,
}

extension SectionTypeX on SectionType {
  String get libelle {
    switch (this) {
      case SectionType.carre:
        return 'Carré';
      case SectionType.rectangulaire:
        return 'Rectangulaire';
      case SectionType.circulaire:
        return 'Circulaire';
    }
  }
}

/// Types d'acier de ferraillage pour les calculs.
class TypeAcier {
  const TypeAcier._(
    this.code,
    this.libelle,
    this.diametreBarreMm,
    this.sourceNormative,
  );

  final String code;
  final String libelle;
  final double diametreBarreMm;
  final String sourceNormative;

  double get surfaceSectionBarreM2 {
    final rayonM = diametreBarreMm / 1000.0 / 2.0;
    return pi * rayonM * rayonM;
  }

  double get masseParMetre {
    const double densiteAcier = 7850.0;
    return surfaceSectionBarreM2 * densiteAcier;
  }

  static const feE400 = TypeAcier._(
    'fe_e_400',
    'Fe E 400 — 16 mm',
    16,
    'BAEL 91 / EC2 — Fe E 400',
  );
  static const feE500 = TypeAcier._(
    'fe_e_500',
    'Fe E 500 — 16 mm',
    16,
    'BAEL 91 / EC2 — Fe E 500',
  );
  static const feB500 = TypeAcier._(
    'fe_b_500',
    'Fe B 500 — 20 mm',
    20,
    'BAEL 91 / EC2 — Fe B 500',
  );

  static const List<TypeAcier> defaults = [
    feE400,
    feE500,
    feB500,
  ];
}
