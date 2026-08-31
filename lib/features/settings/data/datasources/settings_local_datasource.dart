import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsLocalDatasource {
  Future<String?> getBillingMethodKey();
  Future<void> setBillingMethodKey(String key);
}

class SettingsLocalDatasourceImpl implements SettingsLocalDatasource {
  const SettingsLocalDatasourceImpl({required this.prefs});

  final SharedPreferences prefs;

  static const _kBillingMethod = 'settings.billing_method';

  @override
  Future<String?> getBillingMethodKey() async {
    return prefs.getString(_kBillingMethod);
  }

  @override
  Future<void> setBillingMethodKey(String key) async {
    await prefs.setString(_kBillingMethod, key);
  }
}
