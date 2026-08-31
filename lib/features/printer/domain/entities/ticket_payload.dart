import 'package:equatable/equatable.dart';

class TicketLine extends Equatable {
  const TicketLine({
    required this.number,
    required this.amount,
    required this.prize,
    this.subGameName,
  });

  final String number;
  final int amount;
  final int prize;
  final String? subGameName;

  List<dynamic> toQrEntry() => [number, amount];

  @override
  List<Object?> get props => [number, amount, prize, subGameName];
}

class TicketPayload extends Equatable {
  const TicketPayload({
    required this.id,
    required this.gameId,
    required this.gameSlug,
    required this.gameName,
    required this.lines,
    required this.folio,
    required this.date,
    this.drawAt,
    this.seller,
    this.client,
    this.footer,
  });

  final String id;
  final String gameId;
  final String gameSlug;
  final String gameName;
  final List<TicketLine> lines;
  final String folio;
  final DateTime date;
  final DateTime? drawAt;
  final String? seller;
  final String? client;
  final String? footer;

  int get total => lines.fold(0, (sum, l) => sum + l.amount);
  int get totalPrize => lines.fold(0, (sum, l) => sum + l.prize);
  int get count => lines.length;

  // Uses uppercase hex without dashes so the ESC/POS QR encoder picks
  // alphanumeric mode (5.5 bits/char) instead of byte mode (8 bits/char).
  // The scanner reconstructs the UUID on the way back.
  String toQrData() => id.replaceAll('-', '').toUpperCase();

  @override
  List<Object?> get props => [
        id,
        gameId,
        gameSlug,
        gameName,
        lines,
        folio,
        date,
        drawAt,
        seller,
        client,
        footer,
      ];
}
