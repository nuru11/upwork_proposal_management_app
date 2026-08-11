import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/ai_draft.dart';

class AiDraftRepository {
  AiDraftRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<List<AiDraft>> getAll() async {
    final rows = await _db.query(
      'ai_drafts',
      orderBy: 'updated_at DESC',
    );
    return rows.map(AiDraft.fromMap).toList();
  }

  Future<AiDraft?> getById(String id) async {
    final rows = await _db.query(
      'ai_drafts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AiDraft.fromMap(rows.first);
  }

  Future<void> insert(AiDraft draft) async {
    await _db.insert(
      'ai_drafts',
      draft.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(AiDraft draft) async {
    await _db.update(
      'ai_drafts',
      draft.toMap(),
      where: 'id = ?',
      whereArgs: [draft.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('ai_drafts', where: 'id = ?', whereArgs: [id]);
  }
}
