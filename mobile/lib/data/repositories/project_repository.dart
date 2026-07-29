import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/project.dart';

class ProjectRepository {
  ProjectRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<List<Project>> getAll({ProjectType? type}) async {
    final rows = await _db.query(
      'projects',
      orderBy: 'updated_at DESC',
    );
    final projects = rows.map(Project.fromMap).toList();
    if (type == null) return projects;
    return projects.where((p) => p.types.contains(type)).toList();
  }

  Future<Project?> getById(String id) async {
    final rows = await _db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }

  Future<void> insert(Project project) async {
    await _db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Project project) async {
    await _db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}
