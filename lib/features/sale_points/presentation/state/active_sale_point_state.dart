import 'package:equatable/equatable.dart';

import '../../domain/entities/sale_point.dart';

enum ActiveSalePointStatus {
  idle,
  loading,
  needsSelection,
  ready,
  empty,
  error,
}

class ActiveSalePointState extends Equatable {
  const ActiveSalePointState({
    required this.status,
    this.available = const [],
    this.selected,
    this.errorMessage,
  });

  const ActiveSalePointState.idle() : this(status: ActiveSalePointStatus.idle);

  final ActiveSalePointStatus status;
  final List<SalePoint> available;
  final SalePoint? selected;
  final String? errorMessage;

  bool get isReady => status == ActiveSalePointStatus.ready && selected != null;

  bool get requiresSelection =>
      status == ActiveSalePointStatus.needsSelection && available.length > 1;

  ActiveSalePointState copyWith({
    ActiveSalePointStatus? status,
    List<SalePoint>? available,
    SalePoint? selected,
    bool clearSelected = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActiveSalePointState(
      status: status ?? this.status,
      available: available ?? this.available,
      selected: clearSelected ? null : (selected ?? this.selected),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, available, selected, errorMessage];
}
