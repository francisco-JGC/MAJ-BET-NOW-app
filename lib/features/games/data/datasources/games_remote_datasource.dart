import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/game_model.dart';

abstract interface class GamesRemoteDatasource {
  Future<List<GameModel>> fetchGames();
}

class GamesRemoteDatasourceImpl implements GamesRemoteDatasource {
  const GamesRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<List<GameModel>> fetchGames() async {
    try {
      final response = await client.instance.get<List<dynamic>>('/games');
      final data = response.data ?? const [];
      return data
          .map((raw) => GameModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final type = e.type;
      if (type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.connectionError ||
          type == DioExceptionType.receiveTimeout) {
        throw NetworkException(e.message ?? 'Network error');
      }
      throw ServerException(
        e.message ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
