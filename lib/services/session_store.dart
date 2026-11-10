import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o id do usuário logado para manter a sessão entre aberturas do app.
/// Apenas o id é salvo — nunca senha ou hash.
abstract interface class SessionStore {
  Future<int?> readUserId();
  Future<void> saveUserId(int id);
  Future<void> clear();
}

class SharedPrefsSessionStore implements SessionStore {
  static const _key = 'session_user_id';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<int?> readUserId() => _prefs.getInt(_key);

  @override
  Future<void> saveUserId(int id) => _prefs.setInt(_key, id);

  @override
  Future<void> clear() => _prefs.remove(_key);
}

/// Implementação em memória, usada nos testes.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this._id]);

  int? _id;

  @override
  Future<int?> readUserId() async => _id;

  @override
  Future<void> saveUserId(int id) async => _id = id;

  @override
  Future<void> clear() async => _id = null;
}
