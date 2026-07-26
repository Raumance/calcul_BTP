/// Représentations applicatives des doses de béton et des liants cimentaires.
class DosageBeton {
  const DosageBeton._(this.code, this.libelle, this.valeurKgM3);

  final String code;
  final String libelle;
  final double valeurKgM3;

  static const standard = DosageBeton._('standard', 'Standard (300 kg/m³)', 300);
  static const renforce = DosageBeton._('renforce', 'Renforcé (350 kg/m³)', 350);
  static const complexe = DosageBeton._('complexe', 'Complexe (400 kg/m³)', 400);

  static const List<DosageBeton> defaults = [standard, renforce, complexe];
}

class TypeCiment {
  const TypeCiment._(this.code, this.libelle);

  final String code;
  final String libelle;

  static const cpj325 = TypeCiment._('cpj_32_5', 'Ciment CPJ 32.5');
  static const cpj425 = TypeCiment._('cpj_42_5', 'Ciment CPJ 42.5');
  static const cpj525 = TypeCiment._('cpj_52_5', 'Ciment CPJ 52.5');

  static const List<TypeCiment> defaults = [cpj325, cpj425, cpj525];
}

class SacCiment {
  const SacCiment._(this.poidsKg);

  final int poidsKg;

  static const sac25 = SacCiment._(25);
  static const sac35 = SacCiment._(35);
  static const sac50 = SacCiment._(50);

  static const List<SacCiment> defaults = [sac25, sac35, sac50];

  String get libelle => '$poidsKg kg';
}
