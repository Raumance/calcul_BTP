/// Ratio acier / béton selon le type d'ouvrage (BAEL / Eurocode 2).
class RatioFerraillage {
  const RatioFerraillage({
    required this.typeElement,
    required this.valeurKgM3,
    required this.sourceNormative,
  });

  final String typeElement;
  final double valeurKgM3;
  final String sourceNormative;

  static const fondationSuperficielle = RatioFerraillage(
    typeElement: 'fondation_superficielle',
    valeurKgM3: 60,
    sourceNormative: 'BAEL 91 / EC2 — fondations superficielles',
  );
  static const poteau = RatioFerraillage(
    typeElement: 'poteau',
    valeurKgM3: 120,
    sourceNormative: 'BAEL 91 / EC2 — poteaux',
  );
  static const poutre = RatioFerraillage(
    typeElement: 'poutre',
    valeurKgM3: 100,
    sourceNormative: 'BAEL 91 / EC2 — poutres',
  );
  static const dalle = RatioFerraillage(
    typeElement: 'dalle',
    valeurKgM3: 80,
    sourceNormative: 'BAEL 91 / EC2 — dalles',
  );

  static const List<RatioFerraillage> defaults = [
    fondationSuperficielle,
    poteau,
    poutre,
    dalle,
  ];

  String get libelle {
    switch (typeElement) {
      case 'fondation_superficielle':
        return 'Fondation superficielle';
      case 'poteau':
        return 'Poteau';
      case 'poutre':
        return 'Poutre';
      case 'dalle':
        return 'Dalle';
      default:
        return typeElement;
    }
  }
}
