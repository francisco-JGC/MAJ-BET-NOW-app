import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsLocalDatasource {
  Future<String?> getBillingMethodKey();
  Future<void> setBillingMethodKey(String key);

  /// Vibración de la ruleta. Ausente = habilitada: es el comportamiento
  /// por defecto y no queremos que una instalación nueva la tenga apagada.
  bool getRouletteHaptics();
  Future<void> setRouletteHaptics({required bool enabled});
}

class SettingsLocalDatasourceImpl implements SettingsLocalDatasource {
  const SettingsLocalDatasourceImpl({required this.prefs});

  final SharedPreferences prefs;

  static const _kBillingMethod = 'settings.billing_method';
  static const _kRouletteHaptics = 'settings.roulette_haptics';

  @override
  Future<String?> getBillingMethodKey() async {
    return prefs.getString(_kBillingMethod);
  }

  @override
  Future<void> setBillingMethodKey(String key) async {
    await prefs.setString(_kBillingMethod, key);
  }

  @override
  bool getRouletteHaptics() => prefs.getBool(_kRouletteHaptics) ?? true;

  @override
  Future<void> setRouletteHaptics({required bool enabled}) async {
    await prefs.setBool(_kRouletteHaptics, enabled);
  }
}
