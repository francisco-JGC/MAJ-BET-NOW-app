import 'package:equatable/equatable.dart';

class DrawResult extends Equatable {
  const DrawResult({
    required this.id,
    required this.gameId,
    required this.drawAt,
    required this.winningNumber,
  });

  final String id;
  final String gameId;
  final DateTime drawAt;
  final String winningNumber;

  @override
  List<Object?> get props => [id, gameId, drawAt, winningNumber];
}
