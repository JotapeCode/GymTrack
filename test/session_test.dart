import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/controllers/auth_controller.dart';
import 'package:meu_app/database/app_database.dart';
import 'package:meu_app/repositories/user_repository.dart';
import 'package:meu_app/services/password_service.dart';
import 'package:meu_app/services/session_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late UserRepository users;

  setUp(() {
    final passwords = PasswordService(iterations: 10);
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      passwordService: passwords,
      seedDemoData: false,
    );
    users = UserRepository(db, passwords);
  });

  tearDown(() => db.close());

  test('login salva a sessão e outro controller a restaura', () async {
    final store = MemorySessionStore();
    final first = AuthController(users, session: store);
    expect(await first.login('admin@gymtrack.com', 'admin123'), isNull);
    expect(await store.readUserId(), first.currentUser!.id);

    final reopened = AuthController(users, session: store);
    await reopened.restoreSession();
    expect(reopened.currentUser?.email, 'admin@gymtrack.com');
  });

  test('logout apaga a sessão salva', () async {
    final store = MemorySessionStore();
    final auth = AuthController(users, session: store);
    await auth.login('admin@gymtrack.com', 'admin123');
    auth.logout();
    await Future<void>.delayed(Duration.zero);
    expect(await store.readUserId(), isNull);
  });

  test('sessão de usuário inexistente volta para o login', () async {
    final store = MemorySessionStore(9999);
    final auth = AuthController(users, session: store);
    await auth.restoreSession();
    expect(auth.isLoggedIn, isFalse);
    expect(await store.readUserId(), isNull);
  });
}
