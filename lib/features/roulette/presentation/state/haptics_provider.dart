import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../settings/data/datasources/settings_local_datasource.dart';

/// Preferencia de vibración de la ruleta.
///
/// Vive aparte de `SettingsController` a propósito: ese está tipado a
/// `BillingMethod` y convertirlo en un objeto de ajustes tocaría el flujo
/// de facturación, que está en producción. Comparte el mismo
/// SharedPreferences, así que persiste igual.
///
/// Lectura síncrona: el valor ya está en memoria cuando arranca la app,
/// así que no hace falta un AsyncNotifier ni un estado de carga.
class RouletteHapticsController extends Notifier<bool> {
  SettingsLocalDatasource get _store => getIt<SettingsLocalDatasource>();

  @override
  bool build() => _store.getRouletteHaptics();

  Future<void> toggle({required bool enabled}) async {
    state = enabled;
    await _store.setRouletteHaptics(enabled: enabled);
  }
}

final rouletteHapticsProvider =
    NotifierProvider<RouletteHapticsController, bool>(
  RouletteHapticsController.new,
);
