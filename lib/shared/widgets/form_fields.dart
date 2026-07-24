import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    this.suffix,
    this.onChanged,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class PerteSlider extends StatelessWidget {
  const PerteSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.01,
    this.max = 0.20,
    this.label = 'Coefficient de perte',
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ${(value * 100).toStringAsFixed(0)} %',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) * 100).round(),
          activeColor: AppColors.primary,
          label: '${(value * 100).round()} %',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Bannière mode hors-ligne / sync.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    this.syncing = false,
  });

  final bool isOnline;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    if (isOnline && !syncing) return const SizedBox.shrink();
    final bg = isOnline ? AppColors.success : AppColors.offlineBanner;
    final text = !isOnline
        ? 'Hors-ligne — calculs locaux disponibles'
        : 'Synchronisation en cours…';
    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync : Icons.cloud_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.valeur,
    required this.unite,
    required this.referenceNormative,
    this.designation,
    this.details,
    this.onAddToDevis,
  });

  final double valeur;
  final String unite;
  final String referenceNormative;
  final String? designation;
  final Map<String, dynamic>? details;
  final VoidCallback? onAddToDevis;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (designation != null)
              Text(
                designation!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: valeur.toStringAsFixed(
                      valeur == valeur.roundToDouble() ? 0 : 2,
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' $unite',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                referenceNormative,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (onAddToDevis != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddToDevis,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter au devis'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
