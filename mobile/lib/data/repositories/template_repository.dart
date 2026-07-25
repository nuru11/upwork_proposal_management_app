import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/proposal.dart';
import '../models/template.dart';

class TemplateRepository {
  TemplateRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<List<ProposalTemplate>> getAll({ProposalLanguage? language}) async {
    final rows = await _db.query(
      'templates',
      where: language == null ? null : 'language = ?',
      whereArgs: language == null ? null : [language.name],
      orderBy: 'is_favorite DESC, updated_at DESC',
    );
    return rows.map(ProposalTemplate.fromMap).toList();
  }

  Future<ProposalTemplate?> getById(String id) async {
    final rows = await _db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProposalTemplate.fromMap(rows.first);
  }

  Future<void> insert(ProposalTemplate template) async {
    await _db.insert(
      'templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(ProposalTemplate template) async {
    await _db.update(
      'templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, String>> namesByIds(Iterable<String> ids) async {
    final unique = ids.whereType<String>().toSet().toList();
    if (unique.isEmpty) return {};

    final placeholders = List.filled(unique.length, '?').join(',');
    final rows = await _db.query(
      'templates',
      columns: ['id', 'name'],
      where: 'id IN ($placeholders)',
      whereArgs: unique,
    );
    return {
      for (final row in rows) row['id'] as String: row['name'] as String,
    };
  }
}
