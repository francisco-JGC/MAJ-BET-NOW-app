import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remote,
    required this.local,
    required this.tokenStore,
  });

  final AuthRemoteDatasource remote;
  final AuthLocalDatasource local;
  final TokenStore tokenStore;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
  }) async {
    try {
      final session = await remote.login(
        username: username,
        password: password,
      );
      await local.save(session);
      tokenStore.setTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return Right(session);
    } on AccessBlockedException catch (e) {
      return Left(AccessBlockedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSession?>> loadSession() async {
    try {
      final session = await local.read();
      if (session != null) {
        tokenStore.setTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      }
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await local.clear();
      tokenStore.clear();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
