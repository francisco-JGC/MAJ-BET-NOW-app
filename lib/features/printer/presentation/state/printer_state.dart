import 'package:equatable/equatable.dart';

import '../../domain/entities/printer_device.dart';

enum PrinterStatus { idle, loading, ready, error }

class PrinterState extends Equatable {
  const PrinterState({
    required this.status,
    this.bluetoothEnabled = false,
    this.devices = const [],
    this.connectedDevice,
    this.errorMessage,
    this.isConnecting = false,
    this.isPrinting = false,
    this.needsSettings = false,
  });

  const PrinterState.initial()
      : status = PrinterStatus.idle,
        bluetoothEnabled = false,
        devices = const [],
        connectedDevice = null,
        errorMessage = null,
        isConnecting = false,
        isPrinting = false,
        needsSettings = false;

  final PrinterStatus status;
  final bool bluetoothEnabled;
  final List<PrinterDevice> devices;
  final PrinterDevice? connectedDevice;
  final String? errorMessage;
  final bool isConnecting;
  final bool isPrinting;
  final bool needsSettings;

  bool get isConnected => connectedDevice != null;

  PrinterState copyWith({
    PrinterStatus? status,
    bool? bluetoothEnabled,
    List<PrinterDevice>? devices,
    PrinterDevice? connectedDevice,
    bool clearConnectedDevice = false,
    String? errorMessage,
    bool clearError = false,
    bool? isConnecting,
    bool? isPrinting,
    bool? needsSettings,
  }) {
    return PrinterState(
      status: status ?? this.status,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      devices: devices ?? this.devices,
      connectedDevice:
          clearConnectedDevice ? null : connectedDevice ?? this.connectedDevice,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isConnecting: isConnecting ?? this.isConnecting,
      isPrinting: isPrinting ?? this.isPrinting,
      needsSettings: needsSettings ?? this.needsSettings,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bluetoothEnabled,
        devices,
        connectedDevice,
        errorMessage,
        isConnecting,
        isPrinting,
        needsSettings,
      ];
}
