import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/proposal.dart';

class ProposalRepository {
  ProposalRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<List<Proposal>> getAll({
    ProposalStatus? status,
    ProposalLanguage? language,
    ProposalProjectType? projectType,
    String? search,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    if (language != null) {
      where.add('language = ?');
      args.add(language.name);
    }
    if (projectType != null) {
      where.add('project_type = ?');
      args.add(projectType.name);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('(title LIKE ? OR client_name LIKE ? OR body LIKE ?)');
      final q = '%${search.trim()}%';
      args.addAll([q, q, q]);
    }

    final rows = await _db.query(
      'proposals',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );

    return rows.map(Proposal.fromMap).toList();
  }

  Future<Proposal?> getById(String id) async {
    final rows = await _db.query(
      'proposals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Proposal.fromMap(rows.first);
  }

  Future<void> insert(Proposal proposal) async {
    await _db.insert(
      'proposals',
      proposal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Proposal proposal) async {
    await _db.update(
      'proposals',
      proposal.toMap(),
      where: 'id = ?',
      whereArgs: [proposal.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('proposals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<ProposalStatus, int>> countByStatus() async {
    final rows = await _db.rawQuery(
      'SELECT status, COUNT(*) as count FROM proposals GROUP BY status',
    );
    final result = {for (final s in ProposalStatus.values) s: 0};
    for (final row in rows) {
      final status = ProposalStatus.fromStorage(row['status'] as String);
      result[status] = row['count'] as int;
    }
    return result;
  }

  Future<Map<ProposalLanguage, ({int total, int hired})>>
      hireStatsByLanguage() async {
    final rows = await _db.rawQuery('''
      SELECT language,
             COUNT(*) as total,
             SUM(CASE WHEN status = 'hired' THEN 1 ELSE 0 END) as hired
      FROM proposals
      GROUP BY language
    ''');
    final result = {
      for (final lang in ProposalLanguage.values)
        lang: (total: 0, hired: 0),
    };
    for (final row in rows) {
      final language = ProposalLanguage.fromStorage(row['language'] as String);
      result[language] = (
        total: row['total'] as int,
        hired: row['hired'] as int? ?? 0,
      );
    }
    return result;
  }

  Future<List<({String? templateId, int total, int hired})>>
      hireStatsByTemplate() async {
    final rows = await _db.rawQuery('''
      SELECT template_id,
             COUNT(*) as total,
             SUM(CASE WHEN status = 'hired' THEN 1 ELSE 0 END) as hired
      FROM proposals
      WHERE template_id IS NOT NULL
      GROUP BY template_id
      ORDER BY hired DESC, total DESC
    ''');
    return rows
        .map(
          (row) => (
            templateId: row['template_id'] as String?,
            total: row['total'] as int,
            hired: row['hired'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<({int total, int hired})> overallHireStats() async {
    final rows = await _db.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN status = 'hired' THEN 1 ELSE 0 END) as hired
      FROM proposals
    ''');
    if (rows.isEmpty) return (total: 0, hired: 0);
    return (
      total: rows.first['total'] as int? ?? 0,
      hired: rows.first['hired'] as int? ?? 0,
    );
  }
}
