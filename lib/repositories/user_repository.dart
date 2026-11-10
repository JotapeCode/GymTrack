import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_user.dart';
import '../services/password_service.dart';
import 'app_exception.dart';

class UserRepository {
  UserRepository(this._appDatabase, this._passwordService);

  final AppDatabase _appDatabase;
  final PasswordService _passwordService;

  static const _publicColumns = [
    'id',
    'name',
    'email',
    'role',
    'is_active',
    'created_at',
  ];

  Future<Database> get _db => _appDatabase.database;

  /// Retorna o usuário autenticado ou lança [AppException].
  Future<AppUser> authenticate(String email, String password) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AppException('E-mail ou senha incorretos.');
    }
    final row = rows.first;
    final valid = _passwordService.verify(
      password,
      hash: row['password_hash'] as String,
      salt: row['password_salt'] as String,
    );
    if (!valid) throw const AppException('E-mail ou senha incorretos.');
    final user = AppUser.fromMap(row);
    if (!user.isActive) {
      throw const AppException('Conta desativada. Procure o administrador.');
    }
    return user;
  }

  Future<List<AppUser>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'users',
      columns: _publicColumns,
      orderBy: "role = 'admin' DESC, name COLLATE NOCASE",
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      columns: _publicColumns,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> create(AppUser user, String password) async {
    final db = await _db;
    await _ensureEmailAvailable(db, user.email);
    final hashed = _passwordService.hash(password);
    final id = await db.insert('users', {
      ...user.toMap(),
      'email': user.email.trim().toLowerCase(),
      'password_hash': hashed.hash,
      'password_salt': hashed.salt,
    });
    return (await getById(id))!;
  }

  Future<AppUser> update(AppUser user, {String? newPassword}) async {
    final db = await _db;
    await _ensureEmailAvailable(db, user.email, excludeId: user.id);
    final current = await getById(user.id!);
    if (current == null) throw const AppException('Usuário não encontrado.');

    final losesAdmin =
        current.isAdmin &&
        current.isActive &&
        (!user.isAdmin || !user.isActive);
    if (losesAdmin && await _activeAdminCount(db) <= 1) {
      throw const AppException(
        'Deve existir pelo menos um administrador ativo.',
      );
    }

    final values = <String, Object?>{
      'name': user.name.trim(),
      'email': user.email.trim().toLowerCase(),
      'role': user.role.name,
      'is_active': user.isActive ? 1 : 0,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      final hashed = _passwordService.hash(newPassword);
      values['password_hash'] = hashed.hash;
      values['password_salt'] = hashed.salt;
    }
    await db.update('users', values, where: 'id = ?', whereArgs: [user.id]);
    return (await getById(user.id!))!;
  }

  Future<void> changePassword(
    int userId, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) throw const AppException('Usuário não encontrado.');
    final valid = _passwordService.verify(
      currentPassword,
      hash: rows.first['password_hash'] as String,
      salt: rows.first['password_salt'] as String,
    );
    if (!valid) throw const AppException('Senha atual incorreta.');
    final hashed = _passwordService.hash(newPassword);
    await db.update(
      'users',
      {'password_hash': hashed.hash, 'password_salt': hashed.salt},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    final user = await getById(id);
    if (user == null) return;
    if (user.isAdmin && user.isActive && await _activeAdminCount(db) <= 1) {
      throw const AppException(
        'Não é possível excluir o último administrador ativo.',
      );
    }
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> _activeAdminCount(Database db) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM users WHERE role = 'admin' AND is_active = 1",
    );
    return result.first['total'] as int;
  }

  Future<void> _ensureEmailAvailable(
    Database db,
    String email, {
    int? excludeId,
  }) async {
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: excludeId == null ? 'email = ?' : 'email = ? AND id != ?',
      whereArgs: [email.trim(), ?excludeId],
    );
    if (rows.isNotEmpty) {
      throw const AppException('Este e-mail já está cadastrado.');
    }
  }
}
