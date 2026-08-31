import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SalePointsLocalDatasource {
  Future<String?> readSelectedId();
  Future<void> writeSelectedId(String id);
  Future<void> clearSelectedId();
}

class SalePointsLocalDatasourceImpl implements SalePointsLocalDatasource {
  const SalePointsLocalDatasourceImpl({required this.prefs});

  static const _keySelectedId = 'sale_points.selected_id';

  final SharedPreferences prefs;

  @override
  Future<String?> readSelectedId() async {
    return prefs.getString(_keySelectedId);
  }

  @override
  Future<void> writeSelectedId(String id) async {
    await prefs.setString(_keySelectedId, id);
  }

  @override
  Future<void> clearSelectedId() async {
    await prefs.remove(_keySelectedId);
  }
}
