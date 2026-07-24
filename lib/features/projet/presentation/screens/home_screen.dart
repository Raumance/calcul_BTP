import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calcul_projet/core/constants/app_colors.dart';
import 'package:calcul_projet/core/constants/app_constants.dart';
import 'package:calcul_projet/core/providers/core_providers.dart';
import 'package:calcul_projet/core/utils/responsive.dart';
import 'package:calcul_projet/features/auth/presentation/providers/auth_provider.dart';
import 'package:calcul_projet/shared/widgets/app_card.dart';
import 'package:calcul_projet/shared/widgets/chantier_button.dart';

import '../providers/app_session_provider.dart';

class ProjetsScreen extends ConsumerStatefulWidget {
  const ProjetsScreen({super.key});

  @override
  ConsumerState<ProjetsScreen> createState() => _ProjetsScreenState();
}

class _ProjetsScreenState extends ConsumerState<ProjetsScreen> {
  final _nom = TextEditingController();
  final _client = TextEditingController();
  final _adresse = TextEditingController();
  String _devise = 'XOF';

  @override
  void dispose() {
    _nom.dispose();
    _client.dispose();
    _adresse.dispose();
    super.dispose();
  }

  Future<void> _nouveauProjet() async {
    _nom.clear();
    _client.clear();
    _adresse.clear();
    _devise = 'XOF';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nouveau projet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nom,
                  decoration:
                      const InputDecoration(labelText: 'Nom du chantier'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _client,
                  decoration: const InputDecoration(labelText: 'Client'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _adresse,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _devise,
                  decoration: const InputDecoration(labelText: 'Devise'),
                  items: const [
                    DropdownMenuItem(value: 'XOF', child: Text('FCFA (XOF)')),
                    DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                  ],
                  onChanged: (v) => setLocal(() => _devise = v ?? 'XOF'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || _nom.text.trim().isEmpty) return;
    final session = ref.read(appSessionProvider.notifier);
    await session.creerProjet(
      nom: _nom.text.trim(),
      client: _client.text.trim(),
      adresse: _adresse.text.trim(),
      deviseCode: _devise,
    );
    await session.creerDevis(intitule: 'Devis — ${_nom.text.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Projets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nouveauProjet,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: ResponsiveBody(
        child: session.projets.isEmpty
            ? Center(
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.apartment,
                          size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun projet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez un chantier pour rattacher calculs et devis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 16),
                      ChantierButton(
                        label: 'Créer un projet',
                        icon: Icons.add,
                        onPressed: _nouveauProjet,
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.moduleGridCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: context.isCompact ? 2.6 : 2.2,
                ),
                itemCount: session.projets.length,
                itemBuilder: (context, i) {
                  final p = session.projets[i];
                  final selected = p.id == session.projetActifId;
                  return AppCard(
                    highlighted: selected,
                    onTap: () => ref
                        .read(appSessionProvider.notifier)
                        .selectionnerProjet(p.id),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apartment,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.nom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                [
                                  if (p.client.isNotEmpty) p.client,
                                  p.deviseCode,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: AppColors.success),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(AppConstants.appName),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Synchroniser',
                onPressed: session.syncing
                    ? null
                    : () async {
                        final a = ref.read(authProvider);
                        if (a is! AuthAuthenticated) {
                          if (context.mounted) context.push('/auth/login');
                          return;
                        }
                        ref.read(appSessionProvider.notifier).setSyncing(true);
                        try {
                          final r =
                              await ref.read(syncServiceProvider).synchroniser();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sync : ${r.succes} OK · '
                                  '${r.conflits} conflits · '
                                  '${r.erreurs} erreurs',
                                ),
                              ),
                            );
                          }
                        } finally {
                          ref
                              .read(appSessionProvider.notifier)
                              .setSyncing(false);
                        }
                      },
                icon: const Icon(Icons.sync_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth is AuthAuthenticated
                              ? 'Bonjour${auth.user.nom.isNotEmpty ? ', ${auth.user.nom}' : ''}'
                              : 'Prêt pour le chantier',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          session.projetActif != null
                              ? 'Projet actif : ${session.projetActif!.nom}'
                              : 'Sélectionnez ou créez un projet pour démarrer.',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ChantierButton(
                                label: 'Projets',
                                icon: Icons.folder_open_rounded,
                                primary: false,
                                onPressed: () => context.go('/projets'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChantierButton(
                                label: 'Devis',
                                icon: Icons.request_quote_rounded,
                                onPressed: () => context.go('/devis'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Calculateurs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = context.moduleGridCount;
                      final modules = <(IconData, String, String, String)>[
                        (
                          Icons.landscape_rounded,
                          'Terrassement',
                          'Déblais / remblais · DTU 12.1',
                          '/calcul/terrassement'
                        ),
                        (
                          Icons.foundation,
                          'Gros œuvre',
                          'Béton, parpaings, ferraillage',
                          '/calcul/gros-oeuvre'
                        ),
                        (
                          Icons.border_all_rounded,
                          'Cloisons / plafonds',
                          'Plâtre, doublages, Placomûr',
                          '/calcul/cloisons'
                        ),
                        (
                          Icons.format_paint_rounded,
                          'Finitions',
                          'Peinture, carrelage, papier peint',
                          '/calcul/finitions'
                        ),
                        (
                          Icons.electrical_services_rounded,
                          'Électricité',
                          'NF C 15-100 — sections, disjoncteurs',
                          '/calcul/electricite'
                        ),
                        (
                          Icons.map_rounded,
                          'Plan par image',
                          'IA + étalonnage',
                          '/plan'
                        ),
                      ];

                      if (cols == 1) {
                        return Column(
                          children: [
                            for (final m in modules) ...[
                              ModuleCard(
                                icon: m.$1,
                                title: m.$2,
                                subtitle: m.$3,
                                onTap: () => context.push(m.$4),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: modules.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.4,
                        ),
                        itemBuilder: (_, i) {
                          final m = modules[i];
                          return ModuleCard(
                            icon: m.$1,
                            title: m.$2,
                            subtitle: m.$3,
                            onTap: () => context.push(m.$4),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
