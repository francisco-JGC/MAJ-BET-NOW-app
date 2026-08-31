import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/results_repository.dart';
import '../models/draw_result_model.dart';
import '../models/ticket_evaluation_model.dart';
import '../models/winning_ticket_model.dart';

abstract interface class ResultsRemoteDatasource {
  Future<List<DrawResultModel>> listResults(ListDrawResultsQuery query);
  Future<List<WinningTicketModel>> listWinners(ListWinnersQuery query);
  Future<TicketEvaluationModel> evaluateTicket(String ticketId);
}

class ResultsRemoteDatasourceImpl implements ResultsRemoteDatasource {
  const ResultsRemoteDatasourceImpl({required this.client});

  final DioClient client;

  @override
  Future<List<DrawResultModel>> listResults(ListDrawResultsQuery query) async {
    try {
      final response = await client.instance.get<List<dynamic>>(
        '/draw-results',
        queryParameters: query.toQueryParameters(),
      );
      final data = response.data ?? const [];
      return data
          .map((raw) => DrawResultModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<WinningTicketModel>> listWinners(ListWinnersQuery query) async {
    try {
      final response = await client.instance.get<List<dynamic>>(
        '/tickets/winners',
        queryParameters: query.toQueryParameters(),
      );
      final data = response.data ?? const [];
      return data
          .map((raw) =>
              WinningTicketModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<TicketEvaluationModel> evaluateTicket(String ticketId) async {
    try {
      final response = await client.instance.get<Map<String, dynamic>>(
        '/tickets/$ticketId/evaluation',
      );
      final data = response.data;
      if (data == null) throw ServerException('Empty response from server');
      return TicketEvaluationModel.fromJson(data);
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
