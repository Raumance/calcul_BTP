abstract final class Validators {
  static String? required(String? value, [String label = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire.';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, 'L\'email');
    if (base != null) return base;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Adresse email invalide.';
    }
    return null;
  }

  /// ≥ 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre.
  static String? password(String? value) {
    final base = required(value, 'Le mot de passe');
    if (base != null) return base;
    final v = value!;
    if (v.length < 8) return 'Au moins 8 caractères.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins une majuscule.';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Au moins une minuscule.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins un chiffre.';
    return null;
  }

  static String? positiveNumber(String? value, [String label = 'La valeur']) {
    final base = required(value, label);
    if (base != null) return base;
    final n = double.tryParse(value!.replaceAll(',', '.'));
    if (n == null) return 'Nombre invalide.';
    if (n <= 0) return '$label doit être > 0.';
    return null;
  }

  static double? parsePositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    return n;
  }
}
