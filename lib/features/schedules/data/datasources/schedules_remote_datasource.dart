import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/draw_schedule_model.dart';

abstract interface class SchedulesRemoteDatasource {
  Future<List<DrawScheduleModel>> listByGame(String gameId);
}

class SchedulesRemoteDatasourceImpl implements SchedulesRemoteDatasource {
  const SchedulesRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<List<DrawScheduleModel>> listByGame(String gameId) async {
    try {
      final response = await client.instance.get<List<dynamic>>(
        '/games/$gameId/schedules',
      );
      final data = response.data ?? const [];
      return data
          .map((raw) => DrawScheduleModel.fromJson(raw as Map<String, dynamic>))
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
