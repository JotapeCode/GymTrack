import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/app_exception.dart';
import '../repositories/user_repository.dart';
import '../services/session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._users, {SessionStore? session})
    : _session = session ?? MemorySessionStore();

  final UserRepository _users;
  final SessionStore _session;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Retorna `null` em caso de sucesso ou a mensagem de erro.
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _users.authenticate(email, password);
      _currentUser = user;
      await _session.saveUserId(user.id!);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível entrar. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _session.clear();
    notifyListeners();
  }

  /// Restaura a sessão salva ao abrir o app. Usuários removidos ou
  /// desativados desde o último acesso voltam para o login.
  Future<void> restoreSession() async {
    try {
      final id = await _session.readUserId();
      if (id == null) return;
      final user = await _users.getById(id);
      if (user != null && user.isActive) {
        _currentUser = user;
      } else {
        await _session.clear();
      }
    } catch (_) {
      // Falha ao ler a sessão não deve impedir o app de abrir.
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Recarrega o usuário logado (ex.: após o admin editar o próprio perfil).
  /// Se ele tiver sido removido ou desativado, encerra a sessão.
  Future<void> refresh() async {
    final id = _currentUser?.id;
    if (id == null) return;
    final user = await _users.getById(id);
    _currentUser = (user != null && user.isActive) ? user : null;
    if (_currentUser == null) await _session.clear();
    notifyListeners();
  }

  /// Cadastro público: sempre cria um usuário comum e ativo.
  /// Não inicia sessão; retorna `null` em caso de sucesso ou a mensagem de erro.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _users.create(
        AppUser(
          name: name.trim(),
          email: email.trim(),
          role: UserRole.user,
          createdAt: DateTime.now(),
        ),
        password,
      );
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível criar a conta. Tente novamente.';
    }
  }

  Future<String?> updateName(String name) async {
    final user = _currentUser;
    if (user == null) return 'Sessão expirada.';
    try {
      _currentUser = await _users.update(user.copyWith(name: name.trim()));
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> changePassword(String current, String newPassword) async {
    final user = _currentUser;
    if (user == null) return 'Sessão expirada.';
    try {
      await _users.changePassword(
        user.id!,
        currentPassword: current,
        newPassword: newPassword,
      );
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}
