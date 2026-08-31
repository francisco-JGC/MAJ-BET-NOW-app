import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/sale_point_model.dart';

abstract interface class SalePointsRemoteDatasource {
  Future<List<SalePointModel>> fetchMine();
}

class SalePointsRemoteDatasourceImpl implements SalePointsRemoteDatasource {
  const SalePointsRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<List<SalePointModel>> fetchMine() async {
    try {
      final response =
          await client.instance.get<List<dynamic>>('/sale-points/mine');
      final data = response.data ?? const [];
      return data
          .map((raw) => SalePointModel.fromJson(raw as Map<String, dynamic>))
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
