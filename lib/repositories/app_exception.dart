/// Erro de regra de negócio com mensagem pronta para exibição ao usuário.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
