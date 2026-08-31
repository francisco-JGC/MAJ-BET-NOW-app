import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/printer_device.dart';
import '../repositories/printer_repository.dart';

class GetPairedPrinters {
  const GetPairedPrinters({required this.repository});

  final PrinterRepository repository;

  Future<Either<Failure, List<PrinterDevice>>> call() {
    return repository.getPairedDevices();
  }
}
