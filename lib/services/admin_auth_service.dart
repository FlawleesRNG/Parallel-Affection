import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../config/admin_secret.g.dart';

enum AdminAccessLevel { root }

class AdminSession {
  const AdminSession({
    required this.authenticatedAtUtc,
    required this.accessLevel,
  });

  final DateTime authenticatedAtUtc;
  final AdminAccessLevel accessLevel;
}

class AdminLoginResult {
  const AdminLoginResult._({required this.success, this.message});

  const AdminLoginResult.success() : this._(success: true);
  const AdminLoginResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String? message;
}

class AdminAccessDenied implements Exception {
  const AdminAccessDenied();
}

abstract interface class AdminAuthService implements Listenable {
  bool get isAuthenticated;
  AdminAccessLevel? get accessLevel;
  AdminSession? get session;

  Future<AdminLoginResult> authenticate({
    required String username,
    required String password,
  });

  Future<void> logout();
  void requireRootAccess();
}

class LocalAdminAuthService extends ChangeNotifier implements AdminAuthService {
  static const _rootUsername = 'guilherme.felipi';

  AdminSession? _session;
  bool _authenticating = false;

  @override
  bool get isAuthenticated => _session != null;

  @override
  AdminAccessLevel? get accessLevel => _session?.accessLevel;

  @override
  AdminSession? get session => _session;

  bool get authenticating => _authenticating;

  @override
  Future<AdminLoginResult> authenticate({
    required String username,
    required String password,
  }) async {
    if (_authenticating) {
      return const AdminLoginResult.failure('Usuário ou senha incorretos.');
    }
    if (username.isEmpty)
      return const AdminLoginResult.failure('Informe o usuário.');
    if (password.isEmpty)
      return const AdminLoginResult.failure('Informe a senha.');

    _authenticating = true;
    notifyListeners();
    try {
      final validUser = username == _rootUsername;
      final validPassword = _constantTimeEquals(
        _derivePasswordHash(password),
        base64Decode(AdminSecret.hashBase64),
      );
      if (!validUser || !validPassword) {
        return const AdminLoginResult.failure('Usuário ou senha incorretos.');
      }
      _session = AdminSession(
        authenticatedAtUtc: DateTime.now().toUtc(),
        accessLevel: AdminAccessLevel.root,
      );
      return const AdminLoginResult.success();
    } finally {
      _authenticating = false;
      notifyListeners();
    }
  }

  @override
  Future<void> logout() async {
    _session = null;
    notifyListeners();
  }

  @override
  void requireRootAccess() {
    if (_session?.accessLevel != AdminAccessLevel.root) {
      throw const AdminAccessDenied();
    }
  }

  List<int> _derivePasswordHash(String password) => _pbkdf2HmacSha256(
    utf8.encode(password),
    base64Decode(AdminSecret.saltBase64),
    AdminSecret.iterations,
    base64Decode(AdminSecret.hashBase64).length,
  );

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
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
}
