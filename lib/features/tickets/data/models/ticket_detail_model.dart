import '../../domain/entities/ticket_detail.dart';
import 'ticket_summary_model.dart';

class TicketDetailModel extends TicketDetail {
  const TicketDetailModel({
    required super.summary,
    required super.lines,
  });

  factory TicketDetailModel.fromJson(Map<String, dynamic> json) {
    final summary = TicketSummaryModel.fromJson(json);
    final rawLines = (json['lines'] as List<dynamic>? ?? const [])
        .map((raw) => raw as Map<String, dynamic>)
        .map(_lineFromJson)
        .toList();
    rawLines.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return TicketDetailModel(summary: summary, lines: rawLines);
  }

  static TicketLineDetail _lineFromJson(Map<String, dynamic> raw) =>
      TicketLineDetail(
        label: raw['label'] as String,
        amount: (raw['amount'] as num).toInt(),
        prize: (raw['prize'] as num).toInt(),
        orderIndex: (raw['orderIndex'] as num).toInt(),
        subGameId: raw['subGameId'] as String?,
        subGameName: raw['subGameName'] as String?,
      );
}
