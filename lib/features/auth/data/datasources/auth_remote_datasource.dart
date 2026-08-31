import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_session_model.dart';

abstract interface class AuthRemoteDatasource {
  Future<AuthSessionModel> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<AuthSessionModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await client.instance.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = response.data;
      if (data == null) {
        throw ServerException('Empty response', statusCode: response.statusCode);
      }
      return AuthSessionModel.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractMessage(e) ?? e.message ?? 'Login failed';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message);
      }
      // 403 from /auth/login means the admin disabled this account.
      if (status == 403) {
        throw AccessBlockedException(message);
      }
      throw ServerException(message, statusCode: status);
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return null;
  }
}
