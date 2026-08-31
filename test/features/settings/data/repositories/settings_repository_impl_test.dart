import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:majbetnow_app/core/errors/failures.dart';
import 'package:majbetnow_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:majbetnow_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:majbetnow_app/features/settings/domain/entities/billing_method.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements SettingsLocalDatasource {}

void main() {
  late _MockDatasource datasource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    datasource = _MockDatasource();
    repository = SettingsRepositoryImpl(local: datasource);
  });

  group('getBillingMethod', () {
    test('returns stored method when datasource has a value', () async {
      when(() => datasource.getBillingMethodKey())
          .thenAnswer((_) async => 'bluetoothPrinter');

      final result = await repository.getBillingMethod();

      expect(result, const Right<Failure, BillingMethod>(
        BillingMethod.bluetoothPrinter,
      ));
    });

    test('returns default method when datasource has no value', () async {
      when(() => datasource.getBillingMethodKey())
          .thenAnswer((_) async => null);

      final result = await repository.getBillingMethod();

      expect(result, const Right<Failure, BillingMethod>(
        BillingMethod.bluetoothPrinter,
      ));
    });

    test('returns CacheFailure when datasource throws', () async {
      when(() => datasource.getBillingMethodKey())
          .thenThrow(Exception('boom'));

      final result = await repository.getBillingMethod();

      expect(result.isLeft(), isTrue);
      result.match(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('setBillingMethod', () {
    test('persists method key and returns Right(unit)', () async {
      when(() => datasource.setBillingMethodKey(any()))
          .thenAnswer((_) async {});

      final result =
          await repository.setBillingMethod(BillingMethod.bluetoothPrinter);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => datasource.setBillingMethodKey('bluetoothPrinter'))
          .called(1);
    });

    test('returns CacheFailure when datasource throws', () async {
      when(() => datasource.setBillingMethodKey(any()))
          .thenThrow(Exception('boom'));

      final result =
          await repository.setBillingMethod(BillingMethod.bluetoothPrinter);

      expect(result.isLeft(), isTrue);
    });
  });
}
