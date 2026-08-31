import '../../domain/entities/ticket_receipt.dart';

class TicketReceiptModel extends TicketReceipt {
  const TicketReceiptModel({
    required super.id,
    required super.folio,
    required super.drawAt,
    required super.total,
    required super.totalPrize,
    required super.count,
  });

  factory TicketReceiptModel.fromJson(Map<String, dynamic> json) {
    return TicketReceiptModel(
      id: json['id'] as String,
      folio: json['folio'] as String,
      drawAt: DateTime.parse(json['drawAt'] as String),
      total: (json['total'] as num).toInt(),
      totalPrize: (json['totalPrize'] as num).toInt(),
      count: (json['count'] as num).toInt(),
    );
  }
}
