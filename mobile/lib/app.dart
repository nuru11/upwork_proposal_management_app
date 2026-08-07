import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/project_form_screen.dart';
import 'features/profile/projects_list_screen.dart';
import 'features/proposals/ai_proposal_wizard_screen.dart';
import 'features/proposals/proposal_detail_screen.dart';
import 'features/proposals/proposal_form_screen.dart';
import 'features/proposals/proposals_list_screen.dart';
import 'data/models/ai_proposal.dart';
import 'features/stats/stats_screen.dart';
import 'features/templates/template_form_screen.dart';
import 'features/templates/templates_list_screen.dart';
import 'providers/providers.dart';
import 'shared/theme/app_theme.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
    refresh.ping();
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/proposals',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';

      if (authAsync.isLoading) return null;

      final loggedIn = authAsync.value?.isAuthenticated ?? false;
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/proposals';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proposals',
                builder: (context, state) => const ProposalsListScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'new',
                    builder: (context, state) => const ProposalFormScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'ai-wizard',
                    builder: (context, state) {
                      final args = state.extra is AiWizardArgs
                          ? state.extra as AiWizardArgs
                          : null;
                      return AiProposalWizardScreen(args: args);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':id',
                    builder: (context, state) => ProposalDetailScreen(
                      proposalId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootNavigatorKey,
                        path: 'edit',
                        builder: (context, state) => ProposalFormScreen(
                          proposalId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/templates',
                builder: (context, state) => const TemplatesListScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'new',
                    builder: (context, state) => const TemplateFormScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':id/edit',
                    builder: (context, state) => TemplateFormScreen(
                      templateId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'projects',
                    builder: (context, state) => const ProjectsListScreen(),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootNavigatorKey,
                        path: 'new',
                        builder: (context, state) => const ProjectFormScreen(),
                      ),
                      GoRoute(
                        parentNavigatorKey: _rootNavigatorKey,
                        path: ':id/edit',
                        builder: (context, state) => ProjectFormScreen(
                          projectId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Proposals',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProposalApp extends ConsumerStatefulWidget {
  const ProposalApp({super.key});

  @override
  ConsumerState<ProposalApp> createState() => _ProposalAppState();
}

class _ProposalAppState extends ConsumerState<ProposalApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).syncIfAuthenticated();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).syncIfAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Proposal Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
