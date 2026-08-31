import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majbetnow_app/core/di/injection.dart';
import 'package:majbetnow_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    if (!getIt.isRegistered<SharedPreferences>()) {
      await configureDependencies();
    }
  });

  testWidgets('app renders MaterialApp router', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MajbetnowApp()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
