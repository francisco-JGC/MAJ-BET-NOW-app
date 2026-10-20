import 'package:equatable/equatable.dart';

/// Las 38 casillas de una ruleta americana, en el orden físico real de la
/// rueda — no el orden numérico. Importa para la animación: si se pintaran
/// 0,1,2,3... en círculo, la rueda se vería ordenada y falsa.
const List<String> kRoulettePockets = [
  '0', '28', '9', '26', '30', '11', '7', '20', '32', '17',
  '5', '22', '34', '15', '3', '24', '36', '13', '1',
  '00', '27', '10', '25', '29', '12', '8', '19', '31', '18',
  '6', '21', '33', '16', '4', '23', '35', '14', '2',
];

const int kRoulettePocketCount = 38;

/// Números rojos de la ruleta. El resto son negros, salvo 0 y 00 (verdes).
const Set<String> kRedPockets = {
  '1', '3', '5', '7', '9', '12', '14', '16', '18',
  '19', '21', '23', '25', '27', '30', '32', '34', '36',
};

bool isGreenPocket(String n) => n == '0' || n == '00';
bool isRedPocket(String n) => kRedPockets.contains(n);

/// Una apuesta: una casilla con SU monto.
class RouletteBet extends Equatable {
  const RouletteBet({required this.number, required this.amount});

  final String number;
  final int amount;

  Map<String, dynamic> toJson() => {'number': number, 'amount': amount};

  @override
  List<Object?> get props => [number, amount];
}

class RoulettePlay extends Equatable {
  const RoulettePlay({
    required this.id,
    required this.bets,
    required this.totalAmount,
    required this.winningNumber,
    required this.isWin,
    required this.prize,
    required this.isTest,
    required this.createdAt,
  });

  final String id;
  final List<RouletteBet> bets;
  final int totalAmount;

  List<String> get numbers => bets.map((b) => b.number).toList();
  final String winningNumber;
  final bool isWin;
  final int prize;

  /// Jugada de prueba: no cuenta como venta ni entra al historial.
  final bool isTest;

  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, bets, totalAmount, winningNumber, isWin, prize, isTest, createdAt];
}

class RouletteConfig extends Equatable {
  const RouletteConfig({
    required this.winPercentBps,
    required this.prizeMultiplier,
    required this.testMode,
  });

  final int winPercentBps;
  final int prizeMultiplier;

  /// Lo decide el admin desde la web. Con el modo activo la tirada se
  /// registra para auditoría pero no genera factura ni sorteo.
  final bool testMode;

  @override
  List<Object?> get props => [winPercentBps, prizeMultiplier, testMode];
}
