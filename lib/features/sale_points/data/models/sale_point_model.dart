import '../../domain/entities/sale_point.dart';

class SalePointModel extends SalePoint {
  const SalePointModel({
    required super.id,
    required super.name,
    required super.code,
    required super.isActive,
  });

  factory SalePointModel.fromJson(Map<String, dynamic> json) {
    return SalePointModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
