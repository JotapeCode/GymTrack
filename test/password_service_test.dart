import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/services/password_service.dart';

void main() {
  final service = PasswordService(iterations: 100);

  test('gera hash diferente da senha e com salt aleatório', () {
    final a = service.hash('admin123');
    final b = service.hash('admin123');
    expect(a.hash, isNot('admin123'));
    expect(a.salt, isNot(b.salt));
    expect(a.hash, isNot(b.hash));
  });

  test('verifica senha correta e rejeita senha incorreta', () {
    final h = service.hash('segredo1');
    expect(service.verify('segredo1', hash: h.hash, salt: h.salt), isTrue);
    expect(service.verify('segredo2', hash: h.hash, salt: h.salt), isFalse);
  });
}
