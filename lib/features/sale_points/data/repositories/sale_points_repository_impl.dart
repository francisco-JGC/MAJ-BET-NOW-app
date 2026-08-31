import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/sale_point.dart';
import '../../domain/repositories/sale_points_repository.dart';
import '../datasources/sale_points_local_datasource.dart';
import '../datasources/sale_points_remote_datasource.dart';

class SalePointsRepositoryImpl implements SalePointsRepository {
  const SalePointsRepositoryImpl({
    required this.remote,
    required this.local,
  });

  final SalePointsRemoteDatasource remote;
  final SalePointsLocalDatasource local;

  @override
  Future<Either<Failure, List<SalePoint>>> fetchMine() async {
    try {
      final items = await remote.fetchMine();
      return Right(items);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<String?> readSelectedId() => local.readSelectedId();

  @override
  Future<void> saveSelectedId(String id) => local.writeSelectedId(id);

  @override
  Future<void> clearSelectedId() => local.clearSelectedId();
}
