import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/authenticated_user.dart';
import '../../features/auth/presentation/state/auth_controller.dart';

final currentUserProvider = Provider<AuthenticatedUser?>((ref) {
  return ref.watch(authControllerProvider).session?.user;
});
