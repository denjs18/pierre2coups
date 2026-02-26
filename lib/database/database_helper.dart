import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/session.dart';
import '../models/impact.dart';
import '../models/target.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  // Stockage en mémoire pour le web (pas de persistance)
  static final List<Map<String, dynamic>> _webSessions = [];
  static final List<Map<String, dynamic>> _webImpacts = [];
  static final List<Map<String, dynamic>> _webCalibrations = [];
  static int _webNextId = 1;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'pierre2coups.db');
    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weapon TEXT,
        distance REAL,
        shot_count INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        std_deviation REAL,
        mean_radius REAL,
        group_center_x REAL,
        group_center_y REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        firestore_id TEXT UNIQUE,
        user_id TEXT,
        weapon_id TEXT,
        weapon_name TEXT,
        club_id TEXT,
        image_url TEXT,
        c200_score REAL,
        c200_details TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        is_migrated INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE impacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        is_manual INTEGER DEFAULT 0,
        firestore_id TEXT,
        c200_zone INTEGER,
        c200_points REAL,
        distance_from_center REAL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calibration (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        center_x REAL NOT NULL,
        center_y REAL NOT NULL,
        radius REAL NOT NULL,
        pixels_per_cm REAL,
        c200_center_x REAL,
        c200_center_y REAL,
        c200_scale REAL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        club_id TEXT,
        club_name TEXT,
        department TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_sync TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE clubs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        department TEXT NOT NULL,
        member_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE weapons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        manufacturer TEXT NOT NULL,
        model TEXT NOT NULL,
        caliber TEXT NOT NULL,
        category TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE departments (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        region TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_sessions_user ON sessions(user_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_firestore ON sessions(firestore_id)');
    await db.execute('CREATE INDEX idx_sessions_sync ON sessions(sync_status)');
    await db.execute('CREATE INDEX idx_weapons_name ON weapons(name)');
    await db.execute('CREATE INDEX idx_clubs_name ON clubs(name, city)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sessions ADD COLUMN firestore_id TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN weapon_id TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN weapon_name TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN club_id TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN image_url TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN c200_score REAL');
      await db.execute('ALTER TABLE sessions ADD COLUMN c200_details TEXT');
      await db.execute('ALTER TABLE sessions ADD COLUMN updated_at TEXT');
      await db.execute(
          'ALTER TABLE sessions ADD COLUMN sync_status TEXT DEFAULT \'pending\'');
      await db.execute(
          'ALTER TABLE sessions ADD COLUMN is_migrated INTEGER DEFAULT 0');

      await db.execute('ALTER TABLE impacts ADD COLUMN firestore_id TEXT');
      await db.execute('ALTER TABLE impacts ADD COLUMN c200_zone INTEGER');
      await db.execute('ALTER TABLE impacts ADD COLUMN c200_points REAL');
      await db.execute(
          'ALTER TABLE impacts ADD COLUMN distance_from_center REAL');

      await db
          .execute('ALTER TABLE calibration ADD COLUMN c200_center_x REAL');
      await db
          .execute('ALTER TABLE calibration ADD COLUMN c200_center_y REAL');
      await db.execute('ALTER TABLE calibration ADD COLUMN c200_scale REAL');

      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          email TEXT NOT NULL,
          first_name TEXT,
          last_name TEXT,
          club_id TEXT,
          club_name TEXT,
          department TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_sync TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE clubs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          city TEXT NOT NULL,
          department TEXT NOT NULL,
          member_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          synced_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE weapons (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          manufacturer TEXT NOT NULL,
          model TEXT NOT NULL,
          caliber TEXT NOT NULL,
          category TEXT NOT NULL,
          usage_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          synced_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE departments (
          code TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          region TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          action TEXT NOT NULL,
          data TEXT,
          created_at TEXT NOT NULL,
          retry_count INTEGER DEFAULT 0,
          last_error TEXT
        )
      ''');

      await db.execute('CREATE INDEX idx_sessions_user ON sessions(user_id)');
      await db.execute(
          'CREATE INDEX idx_sessions_firestore ON sessions(firestore_id)');
      await db
          .execute('CREATE INDEX idx_sessions_sync ON sessions(sync_status)');
      await db.execute('CREATE INDEX idx_weapons_name ON weapons(name)');
      await db.execute('CREATE INDEX idx_clubs_name ON clubs(name, city)');
    }
  }

  // SESSIONS

  Future<int> insertSession(Session session) async {
    if (kIsWeb) {
      final id = _webNextId++;
      final map = Map<String, dynamic>.from(session.toMap());
      map['id'] = id;
      _webSessions.add(map);
      return id;
    }
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getAllSessions() async {
    if (kIsWeb) {
      return _webSessions.reversed
          .map((m) => Session.fromMap(m))
          .toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<Session?> getSession(int id) async {
    if (kIsWeb) {
      final maps =
          _webSessions.where((m) => m['id'] == id).toList();
      return maps.isEmpty ? null : Session.fromMap(maps.first);
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<int> updateSession(Session session) async {
    if (kIsWeb) {
      final idx =
          _webSessions.indexWhere((m) => m['id'] == session.id);
      if (idx >= 0) {
        _webSessions[idx] = Map<String, dynamic>.from(session.toMap())
          ..['id'] = session.id;
      }
      return idx >= 0 ? 1 : 0;
    }
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    if (kIsWeb) {
      _webImpacts.removeWhere((m) => m['session_id'] == id);
      _webCalibrations.removeWhere((m) => m['session_id'] == id);
      final before = _webSessions.length;
      _webSessions.removeWhere((m) => m['id'] == id);
      return before - _webSessions.length;
    }
    final db = await database;
    await db.delete('impacts', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('calibration', where: 'session_id = ?', whereArgs: [id]);
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // IMPACTS

  Future<int> insertImpact(Impact impact) async {
    if (kIsWeb) {
      final id = _webNextId++;
      final map = Map<String, dynamic>.from(impact.toMap());
      map['id'] = id;
      _webImpacts.add(map);
      return id;
    }
    final db = await database;
    return await db.insert('impacts', impact.toMap());
  }

  Future<List<Impact>> getImpactsForSession(int sessionId) async {
    if (kIsWeb) {
      return _webImpacts
          .where((m) => m['session_id'] == sessionId)
          .map((m) => Impact.fromMap(m))
          .toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'impacts',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return List.generate(maps.length, (i) => Impact.fromMap(maps[i]));
  }

  Future<int> deleteImpact(int id) async {
    if (kIsWeb) {
      final before = _webImpacts.length;
      _webImpacts.removeWhere((m) => m['id'] == id);
      return before - _webImpacts.length;
    }
    final db = await database;
    return await db.delete('impacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteImpactsForSession(int sessionId) async {
    if (kIsWeb) {
      _webImpacts.removeWhere((m) => m['session_id'] == sessionId);
      return;
    }
    final db = await database;
    await db.delete('impacts', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<int> updateImpact(Impact impact) async {
    if (kIsWeb) {
      final idx = _webImpacts.indexWhere((m) => m['id'] == impact.id);
      if (idx >= 0) {
        _webImpacts[idx] = Map<String, dynamic>.from(impact.toMap())
          ..['id'] = impact.id;
      }
      return idx >= 0 ? 1 : 0;
    }
    final db = await database;
    return await db.update(
      'impacts',
      impact.toMap(),
      where: 'id = ?',
      whereArgs: [impact.id],
    );
  }

  // CALIBRATION

  Future<int> insertCalibration(TargetCalibration calibration) async {
    if (kIsWeb) {
      final id = _webNextId++;
      final map = Map<String, dynamic>.from(calibration.toMap());
      map['id'] = id;
      _webCalibrations.add(map);
      return id;
    }
    final db = await database;
    return await db.insert('calibration', calibration.toMap());
  }

  Future<TargetCalibration?> getCalibrationForSession(int sessionId) async {
    if (kIsWeb) {
      final maps =
          _webCalibrations.where((m) => m['session_id'] == sessionId).toList();
      return maps.isEmpty ? null : TargetCalibration.fromMap(maps.first);
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    if (maps.isEmpty) return null;
    return TargetCalibration.fromMap(maps.first);
  }

  Future<int> updateCalibration(TargetCalibration calibration) async {
    if (kIsWeb) {
      final idx =
          _webCalibrations.indexWhere((m) => m['id'] == calibration.id);
      if (idx >= 0) {
        _webCalibrations[idx] =
            Map<String, dynamic>.from(calibration.toMap())
              ..['id'] = calibration.id;
      }
      return idx >= 0 ? 1 : 0;
    }
    final db = await database;
    return await db.update(
      'calibration',
      calibration.toMap(),
      where: 'id = ?',
      whereArgs: [calibration.id],
    );
  }

  Future<void> deleteCalibrationForSession(int sessionId) async {
    if (kIsWeb) {
      _webCalibrations.removeWhere((m) => m['session_id'] == sessionId);
      return;
    }
    final db = await database;
    await db.delete('calibration',
        where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // USERS

  Future<void> saveUser(Map<String, dynamic> user) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    return maps.isEmpty ? null : maps.first;
  }

  Future<void> deleteUser() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('users');
  }

  // CLUBS

  Future<void> saveClub(Map<String, dynamic> club) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('clubs', club,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getClubById(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isEmpty ? null : maps.first;
  }

  Future<List<Map<String, dynamic>>> searchClubs(String query) async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query(
      'clubs',
      where: 'name LIKE ? OR city LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
  }

  // WEAPONS

  Future<void> saveWeapon(Map<String, dynamic> weapon) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('weapons', weapon,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getWeaponById(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weapons',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isEmpty ? null : maps.first;
  }

  Future<List<Map<String, dynamic>>> searchWeaponsLocal(String query) async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query(
      'weapons',
      where: 'name LIKE ? OR manufacturer LIKE ? OR model LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'usage_count DESC',
      limit: 50,
    );
  }

  Future<List<Map<String, dynamic>>> getAllWeapons() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('weapons', orderBy: 'usage_count DESC');
  }

  // SYNC QUEUE

  Future<void> addToSyncQueue(
    String entityType,
    String entityId,
    String action,
    String? data,
  ) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncRetry(int id, String error) async {
    if (kIsWeb) return;
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  // SESSION SYNC

  Future<List<Session>> getPendingSessions() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<void> markSessionAsSynced(int sessionId, String firestoreId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'sessions',
      {
        'sync_status': 'synced',
        'firestore_id': firestoreId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> markSessionSyncError(int sessionId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'sessions',
      {'sync_status': 'error'},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Session>> getUnmigratedSessions() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'is_migrated = ? AND user_id IS NULL',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  // UTILITY

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    db.close();
  }
}
