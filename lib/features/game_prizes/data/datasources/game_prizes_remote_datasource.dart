import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/effective_game_prize_model.dart';

abstract interface class GamePrizesRemoteDatasource {
  Future<List<EffectiveGamePrizeModel>> listBySalePoint(String salePointId);
}

class GamePrizesRemoteDatasourceImpl implements GamePrizesRemoteDatasource {
  const GamePrizesRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<List<EffectiveGamePrizeModel>> listBySalePoint(
    String salePointId,
  ) async {
    try {
      final response = await client.instance.get<Map<String, dynamic>>(
        '/sale-point-game-prizes',
        queryParameters: {'salePointId': salePointId},
      );
      final data = response.data;
      if (data == null) throw ServerException('Empty response');
      final items = (data['items'] as List<dynamic>? ?? const []);
      return items
          .map((raw) =>
              EffectiveGamePrizeModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final type = e.type;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.connectionError ||
        type == DioExceptionType.receiveTimeout) {
      return NetworkException(e.message ?? 'Network error');
    }
    final body = e.response?.data;
    final message = body is Map<String, dynamic>
        ? (body['message']?.toString() ?? e.message ?? 'Server error')
        : (e.message ?? 'Server error');
    return ServerException(message, statusCode: e.response?.statusCode);
  }
}
