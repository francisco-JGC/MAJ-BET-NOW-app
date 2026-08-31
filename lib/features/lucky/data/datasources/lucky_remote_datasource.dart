import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/lucky_daily.dart';
import '../models/lucky_daily_model.dart';

final _isoDate = DateFormat('yyyy-MM-dd');

abstract interface class LuckyRemoteDatasource {
  Future<LuckyDailyModel> findForDate(LuckyKind kind, DateTime date);
  Future<List<LuckyDailyModel>> history(LuckyKind kind, int limit);
}

class LuckyRemoteDatasourceImpl implements LuckyRemoteDatasource {
  const LuckyRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<LuckyDailyModel> findForDate(LuckyKind kind, DateTime date) async {
    try {
      final response = await client.instance.get<Map<String, dynamic>>(
        '/lucky/${kind.apiKey}',
        queryParameters: {'date': _isoDate.format(date)},
      );
      final data = response.data;
      if (data == null) throw ServerException('Empty response from server');
      return LuckyDailyModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<LuckyDailyModel>> history(LuckyKind kind, int limit) async {
    try {
      final response = await client.instance.get<List<dynamic>>(
        '/lucky/${kind.apiKey}/history',
        queryParameters: {'limit': limit},
      );
      final data = response.data ?? const [];
      return data
          .map((raw) => LuckyDailyModel.fromJson(raw as Map<String, dynamic>))
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
    final status = e.response?.statusCode;
    if (status == 404) return NotFoundException();
    final body = e.response?.data;
    final message = body is Map<String, dynamic>
        ? (body['message']?.toString() ?? e.message ?? 'Server error')
        : (e.message ?? 'Server error');
    return ServerException(message, statusCode: status);
  }
}
