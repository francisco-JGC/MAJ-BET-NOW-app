import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/state/auth_controller.dart';
import '../widgets/app_drawer.dart';
import 'nav_items.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  String _titleFor(String route) {
    for (final group in kNavGroups) {
      for (final item in group.items) {
        if (item.route == route) return item.label;
      }
    }
    return '';
  }

  Future<void> _confirmLogout(
    BuildContext context,
    Future<void> Function() onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await onConfirm();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).uri.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(route)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push('/configuracion'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(
              context,
              ref.read(authControllerProvider.notifier).signOut,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
