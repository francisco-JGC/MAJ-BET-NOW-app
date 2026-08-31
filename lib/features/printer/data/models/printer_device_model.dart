import '../../domain/entities/printer_device.dart';

class PrinterDeviceModel extends PrinterDevice {
  const PrinterDeviceModel({required super.name, required super.address});

  factory PrinterDeviceModel.fromJson(Map<String, dynamic> json) {
    return PrinterDeviceModel(
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
      };
}
