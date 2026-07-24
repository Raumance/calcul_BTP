import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/projet/presentation/providers/app_session_provider.dart';
import 'form_fields.dart';

/// Coque responsive : bottom bar (mobile) / sidebar (desktop).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = <_NavTab>[
    _NavTab(label: 'Accueil', icon: Icons.home_rounded, path: '/'),
    _NavTab(label: 'Projets', icon: Icons.folder_rounded, path: '/projets'),
    _NavTab(label: 'Devis', icon: Icons.request_quote_rounded, path: '/devis'),
    _NavTab(label: 'Compte', icon: Icons.person_rounded, path: '/auth/login'),
  ];

  int _indexForLocation(String location, AuthState auth) {
    if (location.startsWith('/projets')) return 1;
    if (location.startsWith('/devis')) return 2;
    if (location.startsWith('/auth')) return 3;
    return 0;
  }

  void _onSelect(BuildContext context, WidgetRef ref, int index) {
    final tab = _tabs[index];
    if (tab.path == '/auth/login') {
      final auth = ref.read(authProvider);
      if (auth is AuthAuthenticated) {
        _showAccountSheet(context, ref, auth);
        return;
      }
    }
    context.go(tab.path);
  }

  void _showAccountSheet(
    BuildContext context,
    WidgetRef ref,
    AuthAuthenticated auth,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                auth.user.nom.isEmpty ? auth.user.email : auth.user.nom,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(auth.user.email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Text(
                auth.user.estAbonne ? 'Abonnement actif' : 'Compte gratuit',
                style: TextStyle(
                  color: auth.user.estAbonne
                      ? AppColors.success
                      : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(ctx);
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final auth = ref.watch(authProvider);
    final session = ref.watch(appSessionProvider);
    final index = _indexForLocation(location, auth);
    final side = context.useSideNav;

    final body = Column(
      children: [
        ConnectivityBanner(
          isOnline: session.isOnline,
          syncing: session.syncing,
        ),
        Expanded(child: child),
      ],
    );

    if (side) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: index,
              onSelect: (i) => _onSelect(context, ref, i),
              auth: auth,
              projetActif: session.projetActif?.nom,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, _tabs.length - 1),
        onDestinationSelected: (i) => _onSelect(context, ref, i),
        indicatorColor: AppColors.primarySoft,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.icon, color: AppColors.primary),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.auth,
    this.projetActif,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final AuthState auth;
  final String? projetActif;

  @override
  Widget build(BuildContext context) {
    final wide = context.isExpanded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: wide ? 260 : 88,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 20 : 12, 20, wide ? 20 : 12, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (wide && projetActif != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Projet : $projetActif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: NavigationRail(
                extended: wide,
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelect,
                labelType: wide
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                minExtendedWidth: 220,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Accueil'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder_rounded),
                    label: Text('Projets'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.request_quote_outlined),
                    selectedIcon: Icon(Icons.request_quote_rounded),
                    label: Text('Devis'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Compte'),
                  ),
                ],
              ),
            ),
            if (wide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  auth is AuthAuthenticated
                      ? (auth as AuthAuthenticated).user.email
                      : 'Mode hors-ligne',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
