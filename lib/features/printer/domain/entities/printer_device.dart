import 'package:equatable/equatable.dart';

class PrinterDevice extends Equatable {
  const PrinterDevice({
    required this.name,
    required this.address,
    this.isSmartPos = false,
  });

  final String name;
  final String address;

  /// Cuando true, el generador de ESC/POS usa columnas size1 (32 chars) para
  /// las filas de números en lugar de size2 (16 chars × width×2). Los SmartPOS
  /// suelen ignorar el comando de ancho doble, imprimiendo solo el 50% del papel.
  final bool isSmartPos;

  PrinterDevice copyWith({bool? isSmartPos}) => PrinterDevice(
        name: name,
        address: address,
        isSmartPos: isSmartPos ?? this.isSmartPos,
      );

  @override
  List<Object?> get props => [name, address, isSmartPos];
}
