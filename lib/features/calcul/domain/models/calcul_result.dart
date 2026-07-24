import 'package:calcul_projet/core/constants/app_constants.dart';

/// Résultat unifié de tout calcul de quantitatif.
class CalculResult {
  const CalculResult({
    required this.valeurPrincipale,
    required this.unite,
    required this.details,
    required this.referenceNormative,
    this.avertissement = AppConstants.disclaimerText,
    this.designation,
  });

  final double valeurPrincipale;
  final String unite;
  final Map<String, dynamic> details;
  final String referenceNormative;
  final String avertissement;
  final String? designation;

  CalculResult copyWith({
    double? valeurPrincipale,
    String? unite,
    Map<String, dynamic>? details,
    String? referenceNormative,
    String? avertissement,
    String? designation,
  }) {
    return CalculResult(
      valeurPrincipale: valeurPrincipale ?? this.valeurPrincipale,
      unite: unite ?? this.unite,
      details: details ?? this.details,
      referenceNormative: referenceNormative ?? this.referenceNormative,
      avertissement: avertissement ?? this.avertissement,
      designation: designation ?? this.designation,
    );
  }

  Map<String, dynamic> toJson() => {
        'valeur_principale': valeurPrincipale,
        'unite': unite,
        'details': details,
        'reference_normative': referenceNormative,
        'avertissement': avertissement,
        if (designation != null) 'designation': designation,
      };

  factory CalculResult.fromJson(Map<String, dynamic> json) => CalculResult(
        valeurPrincipale: (json['valeur_principale'] as num).toDouble(),
        unite: json['unite'] as String,
        details: Map<String, dynamic>.from(json['details'] as Map),
        referenceNormative: json['reference_normative'] as String,
        avertissement:
            json['avertissement'] as String? ?? AppConstants.disclaimerText,
        designation: json['designation'] as String?,
      );
}
