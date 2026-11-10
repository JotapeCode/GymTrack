import 'formatters.dart';

abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, [String field = 'Campo']) =>
      (value == null || value.trim().isEmpty) ? '$field é obrigatório' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    if (!_emailRegex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value, {bool optional = false}) {
    if (value == null || value.isEmpty) {
      return optional ? null : 'Informe a senha';
    }
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o nome';
    if (value.trim().length < 3) return 'Nome muito curto';
    return null;
  }

  static String? reps(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return 'Obrigatório';
    if (n <= 0 || n > 500) return 'Inválido';
    return null;
  }

  static String? weight(String? value) {
    final n = Formatters.parseDecimal(value ?? '');
    if (n == null) return 'Obrigatório';
    if (n < 0 || n > 1000) return 'Inválido';
    return null;
  }
}
