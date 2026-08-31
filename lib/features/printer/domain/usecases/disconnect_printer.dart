import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/printer_repository.dart';

class DisconnectPrinter {
  const DisconnectPrinter({required this.repository});

  final PrinterRepository repository;

  Future<Either<Failure, Unit>> call() {
    return repository.disconnect();
  }
}
