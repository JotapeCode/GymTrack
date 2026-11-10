import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Resultado de um hash de senha: ambos são armazenados no banco.
typedef PasswordHash = ({String hash, String salt});

/// Hash de senhas com PBKDF2-HMAC-SHA256 e salt aleatório por usuário.
/// As senhas nunca são persistidas em texto puro.
class PasswordService {
  PasswordService({this.iterations = 10000});

  final int iterations;
  final Random _random = Random.secure();

  PasswordHash hash(String password) {
    final salt = base64Encode(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return (hash: _derive(password, salt), salt: salt);
  }

  bool verify(String password, {required String hash, required String salt}) {
    final candidate = _derive(password, salt);
    return _constantTimeEquals(candidate, hash);
  }

  String _derive(String password, String salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    // PBKDF2 com um único bloco (saída de 32 bytes = tamanho do SHA-256).
    final firstInput = Uint8List.fromList([
      ...utf8.encode(salt),
      0, 0, 0, 1, //
    ]);
    var u = hmac.convert(firstInput).bytes;
    final result = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return base64Encode(result);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
