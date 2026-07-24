import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/core_providers.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/cgu_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/calcul/presentation/screens/cloisons_finitions_screen.dart';
import 'features/calcul/presentation/screens/electricite_screen.dart';
import 'features/calcul/presentation/screens/gros_oeuvre_screen.dart';
import 'features/calcul/presentation/screens/terrassement_screen.dart';
import 'features/devis/presentation/screens/devis_screen.dart';
import 'features/plan/presentation/screens/plan_screen.dart';
import 'features/projet/presentation/providers/app_session_provider.dart';
import 'features/projet/presentation/screens/home_screen.dart';
import 'features/projet/presentation/screens/splash_screen.dart';
import 'shared/database/local_store.dart';
import 'shared/widgets/app_shell.dart';

class CalculBtpApp extends StatelessWidget {
  const CalculBtpApp({super.key, this.store, this.showSplash = true});

  final LocalStore? store;
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    final local = store ?? LocalStore(inMemory: true);
    return ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
      ],
      child: _AppBootstrap(
        child: _CalculBtpMaterialApp(showSplash: showSplash),
      ),
    );
  }
}

class _CalculBtpMaterialApp extends StatelessWidget {
  const _CalculBtpMaterialApp({required this.showSplash});

  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    final router = showSplash ? _routerWithSplash : _routerNoSplash;
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('fr', 'FR'),
    );
  }
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap({required this.child});
  final Widget child;

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final connectivity = ref.read(connectivityServiceProvider);
    final online = await connectivity.isOnline;
    ref.read(appSessionProvider.notifier).setOnline(online);
    connectivity.onConnectivityChanged.listen((isOnline) async {
      ref.read(appSessionProvider.notifier).setOnline(isOnline);
      if (isOnline) await _trySync();
    });
    if (online) await _trySync();
  }

  Future<void> _trySync() async {
    final session = ref.read(appSessionProvider);
    final auth = ref.read(authProvider);
    if (!session.isOnline || auth is! AuthAuthenticated) return;
    if (!auth.user.estAbonne) return;

    ref.read(appSessionProvider.notifier).setSyncing(true);
    try {
      await ref.read(syncServiceProvider).synchroniser();
      final projetId = session.projetActifId;
      if (projetId != null) {
        await ref.read(realtimeSyncProvider).connect(projetId: projetId);
      }
    } catch (_) {
      // Sync best-effort.
    } finally {
      ref.read(appSessionProvider.notifier).setSyncing(false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

List<RouteBase> _shellTabs() => [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/projets', builder: (_, _) => const ProjetsScreen()),
      GoRoute(path: '/devis', builder: (_, _) => const DevisScreen()),
    ];

List<RouteBase> _detailRoutes() => [
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/auth/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(path: '/auth/cgu', builder: (_, _) => const CguScreen()),
      GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
      GoRoute(
        path: '/calcul/terrassement',
        builder: (_, _) => const TerrassementScreen(),
      ),
      GoRoute(
        path: '/calcul/gros-oeuvre',
        builder: (_, _) => const GrosOeuvreScreen(),
      ),
      GoRoute(
        path: '/calcul/cloisons',
        builder: (_, _) => const CloisonsFinitionsScreen(),
      ),
      GoRoute(
        path: '/calcul/finitions',
        builder: (_, _) => const CloisonsFinitionsScreen(modeFinitions: true),
      ),
      GoRoute(
        path: '/calcul/electricite',
        builder: (_, _) => const ElectriciteScreen(),
      ),
    ];

GoRouter _buildRouter({required bool withSplash}) {
  return GoRouter(
    initialLocation: withSplash ? '/splash' : '/',
    routes: [
      if (withSplash)
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: _shellTabs(),
      ),
      ..._detailRoutes(),
    ],
  );
}

final _routerWithSplash = _buildRouter(withSplash: true);
final _routerNoSplash = _buildRouter(withSplash: false);
