import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/app_exception.dart';
import '../repositories/user_repository.dart';

/// Estado da área administrativa (CRUD de usuários).
class UserAdminController extends ChangeNotifier {
  UserAdminController(this._users);

  final UserRepository _users;

  List<AppUser> _items = const [];
  List<AppUser> get users => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get adminCount => _items.where((u) => u.isAdmin).length;
  int get activeCount => _items.where((u) => u.isActive).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _users.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria (quando `user.id == null`) ou atualiza. Retorna erro ou `null`.
  Future<String?> save(AppUser user, {String? password}) async {
    try {
      if (user.id == null) {
        await _users.create(user, password!);
      } else {
        await _users.update(user, newPassword: password);
      }
      await load();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(AppUser user, {required int currentUserId}) async {
    if (user.id == currentUserId) {
      return 'Você não pode excluir a própria conta enquanto está logado.';
    }
    try {
      await _users.delete(user.id!);
      await load();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}
