import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../services/password_service.dart';
import 'database_seeder.dart';

/// Acesso ao banco SQLite local do GymTrack.
///
/// Tabelas:
/// - users (1) ──< exercises (1) ──< workouts (1) ──< workout_sets
/// - users (1) ──< workouts
class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    this._path,
    PasswordService? passwordService,
    this.seedDemoData = true,
  }) : _factory = factory ?? databaseFactory,
       _passwordService = passwordService ?? PasswordService();

  static const _version = 1;
  static const fileName = 'gymtrack.db';

  final DatabaseFactory _factory;
  final String? _path;
  final PasswordService _passwordService;
  final bool seedDemoData;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final path = _path ?? p.join(await _factory.getDatabasesPath(), fileName);
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _createSchema(db);
          await DatabaseSeeder(
            db,
            _passwordService,
          ).seed(includeDemoData: seedDemoData);
        },
      ),
    );
  }

  Future<void> close() async {
    final db = await _database;
    await db?.close();
    _database = null;
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE COLLATE NOCASE,
          password_hash TEXT NOT NULL,
          password_salt TEXT NOT NULL,
          role TEXT NOT NULL CHECK (role IN ('admin', 'user')),
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )''')
      ..execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          muscle_group TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL
        )''')
      ..execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          exercise_id INTEGER NOT NULL
            REFERENCES exercises(id) ON DELETE CASCADE,
          date TEXT NOT NULL,
          notes TEXT
        )''')
      ..execute('''
        CREATE TABLE workout_sets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL
            REFERENCES workouts(id) ON DELETE CASCADE,
          set_number INTEGER NOT NULL,
          reps INTEGER NOT NULL CHECK (reps > 0),
          weight REAL NOT NULL CHECK (weight >= 0)
        )''')
      ..execute('CREATE INDEX idx_exercises_user ON exercises(user_id)')
      ..execute('CREATE INDEX idx_workouts_user ON workouts(user_id, date)')
      ..execute('CREATE INDEX idx_workouts_exercise ON workouts(exercise_id)')
      ..execute('CREATE INDEX idx_sets_workout ON workout_sets(workout_id)');
    await batch.commit(noResult: true);
  }
}
