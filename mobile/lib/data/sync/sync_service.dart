import 'dart:convert';

import '../models/proposal.dart';
import '../models/template.dart';
import '../remote/api_client.dart';
import '../remote/proposal_api.dart';
import '../remote/template_api.dart';
import '../repositories/proposal_repository.dart';
import '../repositories/template_repository.dart';
import 'connectivity_service.dart';
import 'sync_queue_repository.dart';

class SyncService {
  SyncService({
    required ApiClient apiClient,
    required ProposalApi proposalApi,
    required TemplateApi templateApi,
    required ProposalRepository proposalRepository,
    required TemplateRepository templateRepository,
    required SyncQueueRepository syncQueueRepository,
    required ConnectivityService connectivityService,
  })  : _api = apiClient,
        _proposalApi = proposalApi,
        _templateApi = templateApi,
        _proposals = proposalRepository,
        _templates = templateRepository,
        _queue = syncQueueRepository,
        _connectivity = connectivityService;

  final ApiClient _api;
  final ProposalApi _proposalApi;
  final TemplateApi _templateApi;
  final ProposalRepository _proposals;
  final TemplateRepository _templates;
  final SyncQueueRepository _queue;
  final ConnectivityService _connectivity;

  bool _busy = false;

  Future<void> pushProposalUpsert(Proposal proposal) async {
    await _pushOrEnqueue(
      entityType: 'proposal',
      entityId: proposal.id,
      operation: 'upsert',
      payload: jsonEncode(proposal.toJson()),
      send: () => _proposalApi.upsert(proposal),
    );
  }

  Future<void> pushProposalDelete(String id) async {
    await _pushOrEnqueue(
      entityType: 'proposal',
      entityId: id,
      operation: 'delete',
      send: () => _proposalApi.delete(id),
    );
  }

  Future<void> pushTemplateUpsert(ProposalTemplate template) async {
    await _pushOrEnqueue(
      entityType: 'template',
      entityId: template.id,
      operation: 'upsert',
      payload: jsonEncode(template.toJson()),
      send: () => _templateApi.upsert(template),
    );
  }

  Future<void> pushTemplateDelete(String id) async {
    await _pushOrEnqueue(
      entityType: 'template',
      entityId: id,
      operation: 'delete',
      send: () => _templateApi.delete(id),
    );
  }

  Future<void> flushQueue() async {
    if (!await _canSync()) return;

    final items = await _queue.getAll();
    // Templates first so proposal FK references succeed.
    final ordered = [
      ...items.where((i) => i.entityType == 'template'),
      ...items.where((i) => i.entityType != 'template'),
    ];
    for (final item in ordered) {
      try {
        await _executeQueueItem(item);
        await _queue.remove(item.id);
      } catch (_) {
        await _queue.incrementAttempts(item.id);
      }
    }
  }

  Future<void> pullAndMerge() async {
    if (!await _canSync()) return;

    final data = await _api.getJson('/api/sync');
    final proposalJson = (data['proposals'] as List<dynamic>? ?? const []);
    final templateJson = (data['templates'] as List<dynamic>? ?? const []);

    for (final raw in templateJson) {
      final map = Map<String, dynamic>.from(raw as Map);
      final deletedAt = map['deletedAt'] as String?;
      final id = map['id'] as String;
      if (deletedAt != null) {
        await _templates.delete(id);
        continue;
      }
      final remote = ProposalTemplate.fromJson(map);
      final local = await _templates.getById(remote.id);
      if (local == null || !remote.updatedAt.isBefore(local.updatedAt)) {
        await _templates.insert(remote);
      }
    }

    for (final raw in proposalJson) {
      final map = Map<String, dynamic>.from(raw as Map);
      final deletedAt = map['deletedAt'] as String?;
      final id = map['id'] as String;
      if (deletedAt != null) {
        await _proposals.delete(id);
        continue;
      }
      final remote = Proposal.fromJson(map);
      final local = await _proposals.getById(remote.id);
      if (local == null || !remote.updatedAt.isBefore(local.updatedAt)) {
        await _proposals.insert(remote);
      }
    }
  }

  Future<void> syncNow() async {
    if (_busy) return;
    _busy = true;
    try {
      await flushQueue();
      await pullAndMerge();
    } finally {
      _busy = false;
    }
  }

  Future<void> _pushOrEnqueue({
    required String entityType,
    required String entityId,
    required String operation,
    String? payload,
    required Future<void> Function() send,
  }) async {
    try {
      if (await _canSync()) {
        await send();
        return;
      }
    } catch (_) {
      // Fall through to enqueue.
    }

    await _queue.enqueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
  }

  Future<void> _executeQueueItem(SyncQueueItem item) async {
    if (item.operation == 'delete') {
      if (item.entityType == 'proposal') {
        await _proposalApi.delete(item.entityId);
      } else {
        await _templateApi.delete(item.entityId);
      }
      return;
    }

    if (item.payload == null) return;
    final map = jsonDecode(item.payload!) as Map<String, dynamic>;
    if (item.entityType == 'proposal') {
      await _proposalApi.upsert(Proposal.fromJson(map));
    } else {
      await _templateApi.upsert(ProposalTemplate.fromJson(map));
    }
  }

  Future<bool> _canSync() async {
    if (!await _connectivity.isOnline) return false;
    if (!await _api.hasToken) return false;
    return true;
  }
}
