class TypeSol {
  const TypeSol({
    required this.id,
    required this.libelle,
    required this.coefficientFoisonnement,
  });

  final String id;
  final String libelle;

  /// Coefficient de foisonnement ∈ [1.0, 2.0].
  final double coefficientFoisonnement;

  static const terreVegetale = TypeSol(
    id: 'terre_vegetale',
    libelle: 'Terre végétale',
    coefficientFoisonnement: 1.25,
  );
  static const argile = TypeSol(
    id: 'argile',
    libelle: 'Argile',
    coefficientFoisonnement: 1.30,
  );
  static const sable = TypeSol(
    id: 'sable',
    libelle: 'Sable',
    coefficientFoisonnement: 1.10,
  );
  static const roche = TypeSol(
    id: 'roche',
    libelle: 'Roche',
    coefficientFoisonnement: 1.50,
  );

  static const List<TypeSol> defaults = [
    terreVegetale,
    argile,
    sable,
    roche,
  ];

  TypeSol copyWith({double? coefficientFoisonnement}) => TypeSol(
        id: id,
        libelle: libelle,
        coefficientFoisonnement:
            coefficientFoisonnement ?? this.coefficientFoisonnement,
      );
}
