import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    required this.createdAt,
    required this.attempts,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String? payload;
  final DateTime createdAt;
  final int attempts;

  factory SyncQueueItem.fromMap(Map<String, Object?> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: map['operation'] as String,
      payload: map['payload'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      attempts: map['attempts'] as int? ?? 0,
    );
  }
}

class SyncQueueRepository {
  SyncQueueRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  final _uuid = const Uuid();

  Database get _db => _appDatabase.database;

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    String? payload,
  }) async {
    // Collapse pending ops for the same entity.
    await _db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );

    await _db.insert('sync_queue', {
      'id': _uuid.v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  Future<List<SyncQueueItem>> getAll() async {
    final rows = await _db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<void> remove(String id) async {
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementAttempts(String id) async {
    await _db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }
}
