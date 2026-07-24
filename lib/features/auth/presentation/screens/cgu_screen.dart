import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calcul_projet/core/constants/app_colors.dart';
import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/utils/responsive.dart';
import 'package:calcul_projet/shared/widgets/chantier_button.dart';

/// CGU / responsabilité — exigence CDC.
class CguScreen extends StatelessWidget {
  const CguScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: ResponsiveBody(
        child: ListView(
          children: [
            const Text(
              'Responsabilité et résultats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.disclaimerText,
              style: const TextStyle(height: 1.45, fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              'En utilisant Calculs BTP, vous reconnaissez que :',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const _Bullet(
              'les quantitatifs sont estimatifs et non certifiés ;',
            ),
            const _Bullet(
              'l\'application ne réalise pas de dimensionnement structurel ;',
            ),
            const _Bullet(
              'une vérification par un professionnel compétent reste nécessaire ;',
            ),
            const _Bullet(
              'vos données de projet peuvent être synchronisées si vous êtes abonné.',
            ),
            const SizedBox(height: 24),
            ChantierButton(
              label: 'J\'ai compris',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.primary)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
