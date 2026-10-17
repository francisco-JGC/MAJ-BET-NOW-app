import '../../domain/entities/roulette_play.dart';

class RoulettePlayModel extends RoulettePlay {
  const RoulettePlayModel({
    required super.id,
    required super.numbers,
    required super.amountPerNumber,
    required super.totalAmount,
    required super.winningNumber,
    required super.isWin,
    required super.prize,
    required super.isTest,
    required super.createdAt,
  });

  factory RoulettePlayModel.fromJson(Map<String, dynamic> json) {
    return RoulettePlayModel(
      id: json['id'] as String,
      numbers: (json['numbers'] as List<dynamic>).map((e) => '$e').toList(),
      amountPerNumber: (json['amountPerNumber'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      winningNumber: '${json['winningNumber']}',
      isWin: json['isWin'] as bool,
      prize: (json['prize'] as num).toInt(),
      isTest: json['isTest'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class RouletteConfigModel extends RouletteConfig {
  const RouletteConfigModel({
    required super.winPercentBps,
    required super.prizeMultiplier,
  });

  factory RouletteConfigModel.fromJson(Map<String, dynamic> json) {
    return RouletteConfigModel(
      winPercentBps: (json['winPercentBps'] as num).toInt(),
      prizeMultiplier: (json['prizeMultiplier'] as num).toInt(),
    );
  }
}
