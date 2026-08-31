import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/business_time.dart';
import '../../domain/repositories/sale_limits_repository.dart';
import '../models/sale_limit_availability_model.dart';

abstract interface class SaleLimitsRemoteDatasource {
  Future<SaleLimitAvailabilityModel> getAvailability(
    SaleLimitAvailabilityQuery query,
  );
}

class SaleLimitsRemoteDatasourceImpl implements SaleLimitsRemoteDatasource {
  const SaleLimitsRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<SaleLimitAvailabilityModel> getAvailability(
    SaleLimitAvailabilityQuery query,
  ) async {
    try {
      final response = await client.instance.get<Map<String, dynamic>>(
        '/sale-limits/availability',
        queryParameters: {
          'gameId': query.gameId,
          'salePointId': query.salePointId,
          'drawAt': BusinessTime.toBusinessIso(query.drawAt),
        },
      );
      final data = response.data;
      if (data == null) throw ServerException('Empty response');
      return SaleLimitAvailabilityModel.fromJson(data);
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
