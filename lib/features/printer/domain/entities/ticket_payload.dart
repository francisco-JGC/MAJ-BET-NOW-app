import 'package:equatable/equatable.dart';

/// Distingue si el ticket que se está renderizando es la venta original
/// o una segunda copia (reimpresión física o reenvío por WhatsApp). El
/// header pinta un banner arriba para que el cliente sepa que no es un
/// boleto duplicado con validez adicional.
enum TicketCopyKind { original, reprint, resend }

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
    this.salePoint,
    this.client,
    this.footer,
    this.copyKind = TicketCopyKind.original,
    this.isDate = false,
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
  /// Nombre visible de la sucursal a la que pertenece el vendedor.
  /// Aparece en el header impreso y en la imagen de WhatsApp.
  final String? salePoint;
  final String? client;
  final String? footer;
  final TicketCopyKind copyKind;
  final bool isDate;

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
        salePoint,
        client,
        footer,
        copyKind,
        isDate,
      ];
}
