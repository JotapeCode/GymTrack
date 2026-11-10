import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/auth_controller.dart';
import 'package:meu_app/database/app_database.dart';
import 'package:meu_app/database/database_seeder.dart';
import 'package:meu_app/models/app_user.dart';
import 'package:meu_app/repositories/user_repository.dart';
import 'package:meu_app/services/password_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late AuthController auth;

  setUp(() {
    final passwords = PasswordService(iterations: 10);
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      passwordService: passwords,
      seedDemoData: false,
    );
    auth = AuthController(UserRepository(db, passwords));
  });

  tearDown(() => db.close());

  test('cadastro público cria Usuário Comum e permite login', () async {
    final error = await auth.register(
      name: 'Maria Nova',
      email: 'maria@nova.com',
      password: 'senha123',
    );
    expect(error, isNull);
    expect(auth.isLoggedIn, isFalse, reason: 'cadastro não inicia sessão');

    expect(await auth.login('maria@nova.com', 'senha123'), isNull);
    expect(auth.currentUser!.role, UserRole.user);
    expect(auth.currentUser!.isAdmin, isFalse);
    expect(auth.currentUser!.isActive, isTrue);

    final row = (await (await db.database).query(
      'users',
      where: 'email = ?',
      whereArgs: ['maria@nova.com'],
    )).single;
    expect(row['password_hash'], isNot('senha123'));
  });

  test('cadastro rejeita e-mail já existente', () async {
    final error = await auth.register(
      name: 'Outro Admin',
      email: SeedCredentials.adminEmail,
      password: 'qualquer1',
    );
    expect(error, 'Este e-mail já está cadastrado.');
  });

  test('login do administrador continua funcionando', () async {
    await auth.register(
      name: 'Maria Nova',
      email: 'maria@nova.com',
      password: 'senha123',
    );
    expect(
      await auth.login(
        SeedCredentials.adminEmail,
        SeedCredentials.adminPassword,
      ),
      isNull,
    );
    expect(auth.currentUser!.isAdmin, isTrue);
  });
}
