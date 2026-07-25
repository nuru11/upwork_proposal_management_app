import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/models/proposal.dart';
import '../data/models/template.dart';
import '../data/remote/api_client.dart';
import '../data/remote/proposal_api.dart';
import '../data/remote/template_api.dart';
import '../data/repositories/proposal_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/sync/connectivity_service.dart';
import '../data/sync/sync_queue_repository.dart';
import '../data/sync/sync_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final proposalRepositoryProvider = Provider<ProposalRepository>((ref) {
  return ProposalRepository(ref.watch(appDatabaseProvider));
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.watch(appDatabaseProvider));
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.watch(apiClientProvider);
  return SyncService(
    apiClient: api,
    proposalApi: ProposalApi(api),
    templateApi: TemplateApi(api),
    proposalRepository: ref.watch(proposalRepositoryProvider),
    templateRepository: ref.watch(templateRepositoryProvider),
    syncQueueRepository: ref.watch(syncQueueRepositoryProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.isLoading = false,
    this.error,
  });

  final bool isAuthenticated;
  final String? username;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUsername = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: clearUsername ? null : (username ?? this.username),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final api = ref.read(apiClientProvider);
    await api.loadToken();
    final hasToken = await api.hasToken;
    if (!hasToken) {
      return const AuthState(isAuthenticated: false);
    }
    final username = await api.username;
    return AuthState(isAuthenticated: true, username: username);
  }

  Future<bool> login(String username, String password) async {
    state = AsyncData(
      (state.value ?? const AuthState(isAuthenticated: false)).copyWith(
        isLoading: true,
        clearError: true,
      ),
    );
    try {
      final session = await ref.read(apiClientProvider).login(username, password);
      state = AsyncData(
        AuthState(
          isAuthenticated: true,
          username: session.username,
        ),
      );
      // Fire-and-forget initial sync after login.
      ref.read(syncServiceProvider).syncNow().then((_) {
        ref.read(proposalsProvider.notifier).refresh();
        ref.read(templatesProvider.notifier).refresh();
      });
      return true;
    } catch (e) {
      state = AsyncData(
        AuthState(
          isAuthenticated: false,
          isLoading: false,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(apiClientProvider).logout();
    state = const AsyncData(AuthState(isAuthenticated: false));
  }

  Future<void> syncIfAuthenticated() async {
    final auth = state.value;
    if (auth == null || !auth.isAuthenticated) return;
    await ref.read(syncServiceProvider).syncNow();
    await ref.read(proposalsProvider.notifier).refresh();
    await ref.read(templatesProvider.notifier).refresh();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class ProposalFilter {
  const ProposalFilter({
    this.status,
    this.language,
    this.search = '',
  });

  final ProposalStatus? status;
  final ProposalLanguage? language;
  final String search;

  ProposalFilter copyWith({
    ProposalStatus? status,
    ProposalLanguage? language,
    String? search,
    bool clearStatus = false,
    bool clearLanguage = false,
  }) {
    return ProposalFilter(
      status: clearStatus ? null : (status ?? this.status),
      language: clearLanguage ? null : (language ?? this.language),
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProposalFilter &&
        other.status == status &&
        other.language == language &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(status, language, search);
}

class ProposalFilterNotifier extends Notifier<ProposalFilter> {
  @override
  ProposalFilter build() => const ProposalFilter();

  void setStatus(ProposalStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setLanguage(ProposalLanguage? language) {
    state = state.copyWith(language: language, clearLanguage: language == null);
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void clear() => state = const ProposalFilter();
}

final proposalFilterProvider =
    NotifierProvider<ProposalFilterNotifier, ProposalFilter>(
  ProposalFilterNotifier.new,
);

class ProposalsNotifier extends AsyncNotifier<List<Proposal>> {
  @override
  Future<List<Proposal>> build() async {
    final filter = ref.watch(proposalFilterProvider);
    return ref.read(proposalRepositoryProvider).getAll(
          status: filter.status,
          language: filter.language,
          search: filter.search,
        );
  }

  Future<void> refresh() async {
    final filter = ref.read(proposalFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(proposalRepositoryProvider).getAll(
            status: filter.status,
            language: filter.language,
            search: filter.search,
          ),
    );
  }

  Future<void> save(Proposal proposal, {required bool isNew}) async {
    final repo = ref.read(proposalRepositoryProvider);
    if (isNew) {
      await repo.insert(proposal);
    } else {
      await repo.update(proposal);
    }
    await ref.read(syncServiceProvider).pushProposalUpsert(proposal);
    await refresh();
  }

  Future<void> updateStatus(Proposal proposal, ProposalStatus status) async {
    final updated = proposal.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await ref.read(proposalRepositoryProvider).update(updated);
    await ref.read(syncServiceProvider).pushProposalUpsert(updated);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(proposalRepositoryProvider).delete(id);
    await ref.read(syncServiceProvider).pushProposalDelete(id);
    await refresh();
  }
}

final proposalsProvider =
    AsyncNotifierProvider<ProposalsNotifier, List<Proposal>>(
  ProposalsNotifier.new,
);

final proposalByIdProvider =
    FutureProvider.family<Proposal?, String>((ref, id) async {
  // Re-fetch when proposals list changes.
  ref.watch(proposalsProvider);
  return ref.read(proposalRepositoryProvider).getById(id);
});

class TemplatesNotifier extends AsyncNotifier<List<ProposalTemplate>> {
  @override
  Future<List<ProposalTemplate>> build() {
    return ref.read(templateRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(templateRepositoryProvider).getAll(),
    );
  }

  Future<void> save(ProposalTemplate template, {required bool isNew}) async {
    final repo = ref.read(templateRepositoryProvider);
    if (isNew) {
      await repo.insert(template);
    } else {
      await repo.update(template);
    }
    await ref.read(syncServiceProvider).pushTemplateUpsert(template);
    await refresh();
  }

  Future<void> toggleFavorite(ProposalTemplate template) async {
    final updated = template.copyWith(
      isFavorite: !template.isFavorite,
      updatedAt: DateTime.now(),
    );
    await ref.read(templateRepositoryProvider).update(updated);
    await ref.read(syncServiceProvider).pushTemplateUpsert(updated);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(templateRepositoryProvider).delete(id);
    await ref.read(syncServiceProvider).pushTemplateDelete(id);
    await refresh();
  }
}

final templatesProvider =
    AsyncNotifierProvider<TemplatesNotifier, List<ProposalTemplate>>(
  TemplatesNotifier.new,
);

final templateByIdProvider =
    FutureProvider.family<ProposalTemplate?, String>((ref, id) async {
  ref.watch(templatesProvider);
  return ref.read(templateRepositoryProvider).getById(id);
});

class StatsSnapshot {
  const StatsSnapshot({
    required this.byStatus,
    required this.overall,
    required this.byLanguage,
    required this.byTemplate,
    required this.templateNames,
  });

  final Map<ProposalStatus, int> byStatus;
  final ({int total, int hired}) overall;
  final Map<ProposalLanguage, ({int total, int hired})> byLanguage;
  final List<({String? templateId, int total, int hired})> byTemplate;
  final Map<String, String> templateNames;

  double get hireRate {
    if (overall.total == 0) return 0;
    return overall.hired / overall.total;
  }
}

final statsProvider = FutureProvider<StatsSnapshot>((ref) async {
  // Invalidate when proposals/templates change.
  ref.watch(proposalsProvider);
  ref.watch(templatesProvider);

  final proposalRepo = ref.read(proposalRepositoryProvider);
  final templateRepo = ref.read(templateRepositoryProvider);

  final byStatus = await proposalRepo.countByStatus();
  final overall = await proposalRepo.overallHireStats();
  final byLanguage = await proposalRepo.hireStatsByLanguage();
  final byTemplate = await proposalRepo.hireStatsByTemplate();
  final names = await templateRepo.namesByIds(
    byTemplate.map((e) => e.templateId).whereType<String>(),
  );

  return StatsSnapshot(
    byStatus: byStatus,
    overall: overall,
    byLanguage: byLanguage,
    byTemplate: byTemplate,
    templateNames: names,
  );
});
