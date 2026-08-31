import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/sale_point.dart';
import '../state/active_sale_point_controller.dart';
import '../state/active_sale_point_state.dart';

class SelectSalePointPage extends ConsumerWidget {
  const SelectSalePointPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSalePointProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un puesto'),
        automaticallyImplyLeading: false,
      ),
      body: switch (state.status) {
        ActiveSalePointStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ActiveSalePointStatus.empty => const _EmptyView(),
        ActiveSalePointStatus.error =>
          _ErrorView(message: state.errorMessage ?? 'Error desconocido'),
        _ => _ListView(available: state.available, selected: state.selected),
      },
    );
  }
}

class _ListView extends ConsumerWidget {
  const _ListView({required this.available, required this.selected});

  final List<SalePoint> available;
  final SalePoint? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: available.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final point = available[i];
        final isSelected = point.id == selected?.id;
        return Card(
          child: ListTile(
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.storefront_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(point.name),
            subtitle: Text('Código: ${point.code}'),
            onTap: () async {
              await ref
                  .read(activeSalePointProvider.notifier)
                  .select(point);
              if (context.mounted) context.go('/juegos');
            },
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes puestos de venta asignados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Contacta al administrador para que te asigne al menos un puesto.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => ref
                  .read(activeSalePointProvider.notifier)
                  .loadForCurrentUser(),
            ),
          ],
        ),
      ),
    );
  }
}
