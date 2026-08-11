import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get database => _db;

  static const _dbName = 'proposal_manager.db';
  static const _dbVersion = 8;

  static Future<AppDatabase> open() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = join(documents.path, _dbName);
    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        body TEXT NOT NULL,
        language TEXT NOT NULL,
        project_type TEXT NOT NULL DEFAULT 'other',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_templates_project_type ON templates(project_type)',
    );

    await db.execute('''
      CREATE TABLE proposals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        client_name TEXT,
        job_url TEXT,
        body TEXT NOT NULL,
        language TEXT NOT NULL,
        status TEXT NOT NULL,
        project_type TEXT NOT NULL DEFAULT 'other',
        template_id TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        submitted_at TEXT,
        FOREIGN KEY (template_id) REFERENCES templates (id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_proposals_status ON proposals(status)',
    );
    await db.execute(
      'CREATE INDEX idx_proposals_language ON proposals(language)',
    );
    await db.execute(
      'CREATE INDEX idx_proposals_project_type ON proposals(project_type)',
    );

    await _createProjects(db);
    await _createAiDrafts(db);
    await _createSyncQueue(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createSyncQueue(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE proposals ADD COLUMN project_type TEXT NOT NULL DEFAULT 'other'",
      );
      await db.execute(
        'CREATE INDEX idx_proposals_project_type ON proposals(project_type)',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE templates ADD COLUMN project_type TEXT NOT NULL DEFAULT 'other'",
      );
      await db.execute(
        'CREATE INDEX idx_templates_project_type ON templates(project_type)',
      );
    }
    if (oldVersion < 5) {
      await _createProjects(db);
    }
    if (oldVersion < 6) {
      await _addProjectTypesColumn(db);
    }
    if (oldVersion < 7) {
      await _createAiDrafts(db);
    }
    if (oldVersion < 8) {
      await _addProjectDescriptionColumn(db);
    }
  }

  static Future<void> _createProjects(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        play_store_url TEXT,
        app_store_url TEXT,
        web_url TEXT,
        types TEXT NOT NULL DEFAULT '["other"]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _addProjectTypesColumn(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(projects)');
    final hasTypes = info.any((row) => row['name'] == 'types');
    if (!hasTypes) {
      await db.execute(
        'ALTER TABLE projects ADD COLUMN types TEXT NOT NULL DEFAULT \'["other"]\'',
      );
    }
  }

  static Future<void> _addProjectDescriptionColumn(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(projects)');
    final hasDescription = info.any((row) => row['name'] == 'description');
    if (!hasDescription) {
      await db.execute(
        'ALTER TABLE projects ADD COLUMN description TEXT',
      );
    }
  }

  static Future<void> _createAiDrafts(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_drafts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        job_description TEXT NOT NULL,
        notes TEXT,
        domain TEXT NOT NULL,
        language TEXT NOT NULL,
        issues TEXT NOT NULL DEFAULT '[]',
        solutions TEXT NOT NULL DEFAULT '[]',
        body TEXT NOT NULL,
        client_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_drafts_updated_at ON ai_drafts(updated_at)',
    );
  }

  static Future<void> _createSyncQueue(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at)',
    );
  }

  Future<void> close() => _db.close();
}
