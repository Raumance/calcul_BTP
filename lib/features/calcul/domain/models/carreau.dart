/// Définitions des caractéristiques des carreaux pour les calculs de finition.
class TypeCarreau {
  const TypeCarreau._(
    this.code,
    this.libelle,
    this.categorie,
    this.longueurCm,
    this.largeurCm,
  );

  final String code;
  final String libelle;
  final String categorie;
  final double longueurCm;
  final double largeurCm;

  double get longueurM => longueurCm / 100.0;
  double get largeurM => largeurCm / 100.0;
  double get surface => longueurM * largeurM;
  String get dimensions => '${longueurCm.toInt()}×${largeurCm.toInt()}';

  static const standard20x20 = TypeCarreau._(
    '20x20',
    'Carreau standard 20×20',
    'Standard',
    20,
    20,
  );
  static const standard30x30 = TypeCarreau._(
    '30x30',
    'Carreau standard 30×30',
    'Standard',
    30,
    30,
  );
  static const standard30x60 = TypeCarreau._(
    '30x60',
    'Carreau standard 30×60',
    'Standard',
    30,
    60,
  );
  static const standard45x45 = TypeCarreau._(
    '45x45',
    'Carreau standard 45×45',
    'Standard',
    45,
    45,
  );
  static const nonStandard25x40 = TypeCarreau._(
    '25x40',
    'Carreau non standard 25×40',
    'Non standard',
    25,
    40,
  );

  static const List<TypeCarreau> defaults = [
    standard20x20,
    standard30x30,
    standard30x60,
    standard45x45,
    nonStandard25x40,
  ];
}
