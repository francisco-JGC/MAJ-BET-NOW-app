import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';

abstract interface class AuthLocalDatasource {
  Future<AuthSessionModel?> read();
  Future<void> save(AuthSessionModel session);
  Future<void> clear();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  const AuthLocalDatasourceImpl({required this.storage});

  final FlutterSecureStorage storage;

  static const _key = 'auth.session';

  @override
  Future<AuthSessionModel?> read() async {
    final raw = await storage.read(key: _key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(json);
    } catch (_) {
      await storage.delete(key: _key);
      return null;
    }
  }

  @override
  Future<void> save(AuthSessionModel session) async {
    await storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await storage.delete(key: _key);
  }
}
