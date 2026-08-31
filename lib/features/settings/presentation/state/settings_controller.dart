import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/billing_method.dart';
import '../../domain/usecases/get_billing_method.dart';
import '../../domain/usecases/set_billing_method.dart';

class SettingsController extends AsyncNotifier<BillingMethod> {
  late final _getBillingMethod = getIt<GetBillingMethod>();
  late final _setBillingMethod = getIt<SetBillingMethod>();

  @override
  Future<BillingMethod> build() async {
    final result = await _getBillingMethod();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (method) => method,
    );
  }

  Future<void> changeBillingMethod(BillingMethod method) async {
    final previous = state.value;
    state = AsyncValue.data(method);
    final result = await _setBillingMethod(method);
    result.match(
      (failure) {
        if (previous != null) {
          state = AsyncValue.data(previous);
        } else {
          state = AsyncValue.error(failure.message, StackTrace.current);
        }
      },
      (_) {},
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, BillingMethod>(
  SettingsController.new,
);
