import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

Future<void> main() async {
  stderr.write('Admin password: ');
  stdin.echoMode = false;
  final password = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  stderr.writeln();
  if (password.isEmpty) {
    stderr.writeln('Password cannot be empty.');
    exitCode = 1;
    return;
  }

  const iterations = 210000;
  final salt = _secureBytes(16);
  final hash = _pbkdf2HmacSha256(utf8.encode(password), salt, iterations, 32);

  stdout.writeln(
    "abstract final class AdminSecret {\n"
    "  static const version = 1;\n"
    "  static const algorithm = 'pbkdf2-hmac-sha256';\n"
    "  static const iterations = $iterations;\n"
    "  static const saltBase64 = '${base64Encode(salt)}';\n"
    "  static const hashBase64 = '${base64Encode(hash)}';\n"
    "}",
  );
}

List<int> _secureBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

List<int> _pbkdf2HmacSha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int length,
) {
  final blocks = <int>[];
  var blockIndex = 1;
  while (blocks.length < length) {
    final blockSalt = [
      ...salt,
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];
    var u = Hmac(sha256, password).convert(blockSalt).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = Hmac(sha256, password).convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    blocks.addAll(t);
    blockIndex++;
  }
  return blocks.take(length).toList();
}
