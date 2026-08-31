import '../../domain/entities/sale_limit_availability.dart';

class SaleLimitAvailabilityModel extends SaleLimitAvailability {
  const SaleLimitAvailabilityModel({
    required super.limit,
    required super.usage,
  });

  factory SaleLimitAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final rawUsage = json['usage'] as Map<String, dynamic>? ?? const {};
    final usage = <String, int>{};
    for (final entry in rawUsage.entries) {
      final value = entry.value;
      if (value is num) usage[entry.key] = value.toInt();
    }
    final limitRaw = json['limit'];
    return SaleLimitAvailabilityModel(
      limit: limitRaw is num ? limitRaw.toInt() : null,
      usage: usage,
    );
  }
}
