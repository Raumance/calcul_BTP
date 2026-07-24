class DevisModel {
  const DevisModel({
    required this.id,
    required this.projetId,
    required this.intitule,
    required this.dateDevis,
    required this.deviseCode,
    required this.tauxConversion,
    required this.lignes,
    this.statut = 'brouillon',
  });

  final String id;
  final String projetId;
  final String intitule;
  final DateTime dateDevis;
  final String deviseCode;
  final double tauxConversion;
  final String statut;
  final List<LigneDevisModel> lignes;

  Map<String, List<LigneDevisModel>> get lignesParPhase {
    final map = <String, List<LigneDevisModel>>{};
    for (final l in lignes) {
      (map[l.phase] ??= []).add(l);
    }
    return map;
  }

  Map<String, double> get sousTotauxParPhase => lignesParPhase.map(
        (phase, ll) => MapEntry(phase, ll.fold(0.0, (s, l) => s + l.total)),
      );

  double get totalGeneral => lignes.fold(0.0, (s, l) => s + l.total);

  DevisModel convertir(String nouvelleDevise, double nouveauTaux) {
    final facteur = nouveauTaux / tauxConversion;
    return DevisModel(
      id: id,
      projetId: projetId,
      intitule: intitule,
      dateDevis: dateDevis,
      deviseCode: nouvelleDevise,
      tauxConversion: nouveauTaux,
      statut: statut,
      lignes: lignes.map((l) => l.convertir(facteur)).toList(),
    );
  }

  DevisModel copyWith({List<LigneDevisModel>? lignes, String? statut}) =>
      DevisModel(
        id: id,
        projetId: projetId,
        intitule: intitule,
        dateDevis: dateDevis,
        deviseCode: deviseCode,
        tauxConversion: tauxConversion,
        statut: statut ?? this.statut,
        lignes: lignes ?? this.lignes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projet_id': projetId,
        'intitule': intitule,
        'date_devis': dateDevis.toIso8601String(),
        'devise_code': deviseCode,
        'taux_conversion': tauxConversion,
        'statut': statut,
        'lignes': lignes.map((l) => l.toJson()).toList(),
      };

  factory DevisModel.fromJson(Map<String, dynamic> json) => DevisModel(
        id: json['id'] as String,
        projetId: json['projet_id'] as String? ?? json['projetId'] as String,
        intitule: json['intitule'] as String? ?? '',
        dateDevis: DateTime.tryParse(json['date_devis'] as String? ?? '') ??
            DateTime.now(),
        deviseCode: json['devise_code'] as String? ?? 'XOF',
        tauxConversion: (json['taux_conversion'] as num?)?.toDouble() ?? 1,
        statut: json['statut'] as String? ?? 'brouillon',
        lignes: (json['lignes'] as List? ?? [])
            .map((e) => LigneDevisModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class LigneDevisModel {
  const LigneDevisModel({
    required this.id,
    required this.designation,
    required this.phase,
    required this.quantite,
    required this.unite,
    required this.prixUnitaire,
    required this.coefficientPerte,
    required this.ordre,
    this.calculId,
  });

  final String id;
  final String designation;
  final String phase;
  final double quantite;
  final String unite;
  final double prixUnitaire;
  final double coefficientPerte;
  final int ordre;
  final String? calculId;

  double get total => quantite * prixUnitaire;

  LigneDevisModel convertir(double facteur) => LigneDevisModel(
        id: id,
        designation: designation,
        phase: phase,
        quantite: quantite,
        unite: unite,
        prixUnitaire: prixUnitaire * facteur,
        coefficientPerte: coefficientPerte,
        ordre: ordre,
        calculId: calculId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'designation': designation,
        'phase': phase,
        'quantite': quantite,
        'unite': unite,
        'prix_unitaire': prixUnitaire,
        'coefficient_perte': coefficientPerte,
        'ordre': ordre,
        'calcul_id': calculId,
      };

  factory LigneDevisModel.fromJson(Map<String, dynamic> json) =>
      LigneDevisModel(
        id: json['id'] as String,
        designation: json['designation'] as String? ?? '',
        phase: json['phase'] as String? ?? '',
        quantite: (json['quantite'] as num?)?.toDouble() ?? 0,
        unite: json['unite'] as String? ?? '',
        prixUnitaire: (json['prix_unitaire'] as num?)?.toDouble() ?? 0,
        coefficientPerte:
            (json['coefficient_perte'] as num?)?.toDouble() ?? 0,
        ordre: json['ordre'] as int? ?? 0,
        calculId: json['calcul_id'] as String?,
      );
}

/// Ordre d'affichage des phases dans un devis.
const List<String> phasesOrdre = [
  'terrassement',
  'fondation',
  'gros_oeuvre',
  'finition',
];

String libellePhase(String phase) => switch (phase) {
      'terrassement' => 'Terrassement',
      'fondation' => 'Fondation',
      'gros_oeuvre' => 'Gros œuvre',
      'finition' => 'Finition',
      _ => phase,
    };
