import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/printer_device_model.dart';

abstract interface class PrinterLocalDatasource {
  Future<PrinterDeviceModel?> getLastConnected();
  Future<void> saveLastConnected(PrinterDeviceModel device);
  Future<void> clearLastConnected();
}

class PrinterLocalDatasourceImpl implements PrinterLocalDatasource {
  const PrinterLocalDatasourceImpl({required this.prefs});

  final SharedPreferences prefs;

  static const _kLastConnected = 'printer.last_connected';

  @override
  Future<PrinterDeviceModel?> getLastConnected() async {
    final raw = prefs.getString(_kLastConnected);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PrinterDeviceModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLastConnected(PrinterDeviceModel device) async {
    await prefs.setString(_kLastConnected, jsonEncode(device.toJson()));
  }

  @override
  Future<void> clearLastConnected() async {
    await prefs.remove(_kLastConnected);
  }
}
