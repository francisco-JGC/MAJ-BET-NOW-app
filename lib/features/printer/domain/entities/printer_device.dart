import 'package:equatable/equatable.dart';

class PrinterDevice extends Equatable {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;

  @override
  List<Object?> get props => [name, address];
}
