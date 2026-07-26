/// Définitions des caractéristiques de parpaings et de briques pour le calcul.
class TypeParpaing {
  const TypeParpaing._(
    this.code,
    this.libelle,
    this.categorie,
    this.longueurCm,
    this.hauteurCm,
    this.epaisseurCm,
  );

  final String code;
  final String libelle;
  final String categorie;
  final double longueurCm;
  final double hauteurCm;
  final double epaisseurCm;

  double get longueurM => longueurCm / 100.0;
  double get hauteurM => hauteurCm / 100.0;
  double get epaisseurM => epaisseurCm / 100.0;
  double get surface => longueurM * hauteurM;
  String get dimensions => '${longueurCm.toInt()}×${hauteurCm.toInt()}×${epaisseurCm.toInt()}';

  static const parpaing50x20x20 = TypeParpaing._(
    '50x20x20',
    'Parpaing standard 50×20×20',
    'Standard',
    50,
    20,
    20,
  );
  static const parpaing50x20x10 = TypeParpaing._(
    '50x20x10',
    'Parpaing standard 50×20×10',
    'Standard',
    50,
    20,
    10,
  );
  static const parpaing40x20x10 = TypeParpaing._(
    '40x20x10',
    'Parpaing Gabon 40×20×10',
    'Non standard',
    40,
    20,
    10,
  );
  static const parpaing40x20x15 = TypeParpaing._(
    '40x20x15',
    'Parpaing Gabon 40×20×15',
    'Non standard',
    40,
    20,
    15,
  );
  static const parpaing40x20x20 = TypeParpaing._(
    '40x20x20',
    'Parpaing Gabon 40×20×20',
    'Non standard',
    40,
    20,
    20,
  );
  static const parpaing40x20x12 = TypeParpaing._(
    '40x20x12',
    'Parpaing Gabon 40×20×12',
    'Non standard',
    40,
    20,
    12,
  );

  static const List<TypeParpaing> defaults = [
    parpaing50x20x20,
    parpaing50x20x10,
    parpaing40x20x10,
    parpaing40x20x15,
    parpaing40x20x20,
    parpaing40x20x12,
  ];
}

class TypeBrique {
  const TypeBrique._(
    this.code,
    this.libelle,
    this.longueurCm,
    this.hauteurCm,
    this.epaisseurCm,
  );

  final String code;
  final String libelle;
  final double longueurCm;
  final double hauteurCm;
  final double epaisseurCm;

  double get longueurM => longueurCm / 100.0;
  double get hauteurM => hauteurCm / 100.0;
  double get epaisseurM => epaisseurCm / 100.0;
  double get surface => longueurM * hauteurM;
  String get dimensions => '${longueurCm.toInt()}×${hauteurCm.toInt()}×${epaisseurCm.toInt()}';

  static const standard27x13x7 = TypeBrique._(
    '27x13x7',
    'Brique standard 27×13×7',
    27,
    13,
    7,
  );
  static const standard30x15x7 = TypeBrique._(
    '30x15x7',
    'Brique standard 30×15×7',
    30,
    15,
    7,
  );
  static const nonStandard20x10x5 = TypeBrique._(
    '20x10x5',
    'Brique non standard 20×10×5',
    20,
    10,
    5,
  );
  static const nonStandard25x12x6 = TypeBrique._(
    '25x12x6',
    'Brique non standard 25×12×6',
    25,
    12,
    6,
  );

  static const List<TypeBrique> defaults = [
    standard27x13x7,
    standard30x15x7,
    nonStandard20x10x5,
    nonStandard25x12x6,
  ];
}
