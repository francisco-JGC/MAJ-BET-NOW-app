import '../../domain/entities/draw_result.dart';

class DrawResultModel extends DrawResult {
  const DrawResultModel({
    required super.id,
    required super.gameId,
    required super.drawAt,
    required super.winningNumber,
  });

  factory DrawResultModel.fromJson(Map<String, dynamic> json) {
    return DrawResultModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      drawAt: DateTime.parse(json['drawAt'] as String),
      winningNumber: json['winningNumber'] as String,
    );
  }
}
