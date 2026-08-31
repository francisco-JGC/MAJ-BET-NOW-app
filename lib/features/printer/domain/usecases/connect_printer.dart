import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/printer_repository.dart';

class ConnectPrinter {
  const ConnectPrinter({required this.repository});

  final PrinterRepository repository;

  Future<Either<Failure, Unit>> call(String address) {
    return repository.connect(address);
  }
}
