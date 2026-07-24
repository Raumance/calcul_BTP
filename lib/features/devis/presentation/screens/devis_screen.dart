import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calcul_projet/core/constants/app_colors.dart';
import 'package:calcul_projet/core/utils/freemium_guard.dart';
import 'package:calcul_projet/core/utils/number_formatter.dart';
import 'package:calcul_projet/core/utils/responsive.dart';
import 'package:calcul_projet/features/devis/data/devis_export_service.dart';
import 'package:calcul_projet/features/devis/domain/models/devis.dart';
import 'package:calcul_projet/features/projet/presentation/providers/app_session_provider.dart';
import 'package:calcul_projet/shared/widgets/app_card.dart';
import 'package:calcul_projet/shared/widgets/chantier_button.dart';
import 'package:calcul_projet/shared/widgets/disclaimer_banner.dart';

class DevisScreen extends ConsumerWidget {
  const DevisScreen({super.key});

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
  ) async {
    final session = ref.read(appSessionProvider);
    final devis = session.devisActif;
    if (devis == null) return;

    final ok = FreemiumGuard.peutAcceder(
      estConnecte: session.estConnecte,
      estAbonne: session.estAbonne,
      fonctionnalite: format == ExportFormat.pdf ? 'export_pdf' : 'export_excel',
    );
    if (!ok && format != ExportFormat.csv) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export local'),
          content: const Text(
            'L\'export cloud nécessite un abonnement.\n'
            'Générer quand même un fichier local sur cet appareil ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Exporter'),
            ),
          ],
        ),
      );
      if (proceed != true) {
        if (context.mounted) context.push('/auth/login');
        return;
      }
    }

    try {
      await DevisExportService().exporterEtPartager(
        devis: devis,
        projet: session.projetActif,
        format: format,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export impossible : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final devis = session.devisActif;

    if (devis == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Devis')),
        body: ResponsiveBody(
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.request_quote_outlined,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun devis actif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez un projet puis ajoutez un calcul.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  ChantierButton(
                    label: 'Voir les projets',
                    onPressed: () => context.go('/projets'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(devis.intitule),
        actions: [
          PopupMenuButton<String>(
            onSelected: (code) {
              final taux = code == 'EUR' ? 655.957 : 1.0;
              ref.read(appSessionProvider.notifier).convertirDevis(
                    code,
                    code == devis.deviseCode ? devis.tauxConversion : taux,
                  );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'XOF', child: Text('FCFA (XOF)')),
              PopupMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                label: Text(
                  devis.deviseCode,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                backgroundColor: AppColors.primarySoft,
                side: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          children: [
            for (final phase in phasesOrdre)
              if (devis.lignesParPhase.containsKey(phase)) ...[
                Text(
                  libellePhase(phase),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...devis.lignesParPhase[phase]!.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l.designation,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${NumberFormatter.formatQuantite(l.quantite)} ${l.unite}'
                          ' × ${NumberFormatter.formatMontant(l.prixUnitaire, devis.deviseCode)}',
                        ),
                        trailing: Text(
                          NumberFormatter.formatMontant(
                            l.total,
                            devis.deviseCode,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Sous-total : ${NumberFormatter.formatMontant(devis.sousTotauxParPhase[phase]!, devis.deviseCode)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total général',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    NumberFormatter.formatMontant(
                      devis.totalGeneral,
                      devis.deviseCode,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const DisclaimerBanner(),
            const SizedBox(height: 16),
            if (context.isCompact) ...[
              ChantierButton(
                label: 'Exporter PDF',
                icon: Icons.picture_as_pdf,
                onPressed: () => _export(context, ref, ExportFormat.pdf),
              ),
              const SizedBox(height: 8),
              ChantierButton(
                label: 'Exporter Excel',
                icon: Icons.table_chart_outlined,
                primary: false,
                onPressed: () => _export(context, ref, ExportFormat.excel),
              ),
              TextButton.icon(
                onPressed: () => _export(context, ref, ExportFormat.csv),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exporter CSV'),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: ChantierButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: () =>
                          _export(context, ref, ExportFormat.pdf),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChantierButton(
                      label: 'Excel',
                      icon: Icons.table_chart_outlined,
                      primary: false,
                      onPressed: () =>
                          _export(context, ref, ExportFormat.excel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChantierButton(
                      label: 'CSV',
                      icon: Icons.description_outlined,
                      primary: false,
                      onPressed: () =>
                          _export(context, ref, ExportFormat.csv),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
