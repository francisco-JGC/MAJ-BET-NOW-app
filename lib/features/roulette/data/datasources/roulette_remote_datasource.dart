import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/roulette_play.dart';
import '../models/roulette_models.dart';

abstract interface class RouletteRemoteDatasource {
  Future<RouletteConfigModel> getConfig(String salePointId);
  Future<RoulettePlayModel> play({
    required String salePointId,
    required List<RouletteBet> bets,
    required bool isTest,
  });
  Future<List<RoulettePlayModel>> history({
    required String salePointId,
    required int limit,
  });
}

class RouletteRemoteDatasourceImpl implements RouletteRemoteDatasource {
  const RouletteRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<RouletteConfigModel> getConfig(String salePointId) async {
    try {
      final res = await client.instance.get<Map<String, dynamic>>(
        '/roulette/config',
        queryParameters: {'salePointId': salePointId},
      );
      final data = res.data;
      if (data == null) throw ServerException('Respuesta vacía');
      return RouletteConfigModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_messageOf(e));
    }
  }

  @override
  Future<RoulettePlayModel> play({
    required String salePointId,
    required List<RouletteBet> bets,
    required bool isTest,
  }) async {
    try {
      final res = await client.instance.post<Map<String, dynamic>>(
        '/roulette/play',
        data: {
          'salePointId': salePointId,
          'bets': bets.map((b) => b.toJson()).toList(),
          'isTest': isTest,
        },
      );
      final data = res.data;
      if (data == null) throw ServerException('Respuesta vacía');
      return RoulettePlayModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_messageOf(e));
    }
  }

  @override
  Future<List<RoulettePlayModel>> history({
    required String salePointId,
    required int limit,
  }) async {
    try {
      final res = await client.instance.get<Map<String, dynamic>>(
        '/roulette/plays',
        queryParameters: {'salePointId': salePointId, 'limit': limit},
      );
      final items = res.data?['items'] as List<dynamic>? ?? const [];
      return items
          .map((e) => RoulettePlayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_messageOf(e));
    }
  }

  /// El mensaje útil del backend viaja en el body, no en `e.message`:
  /// Dio pone ahí un texto genérico del tipo "invalid status code 400",
  /// que es lo que terminaba en pantalla como una excepción enorme.
  String _messageOf(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return e.message ?? 'Error de red';
  }
}
