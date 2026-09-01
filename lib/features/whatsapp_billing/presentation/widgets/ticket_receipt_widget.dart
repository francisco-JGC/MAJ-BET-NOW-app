import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../printer/domain/entities/ticket_payload.dart';

/// Color de branding para textos del ticket (header, tabla, notas, total,
/// divisores). `primaryDark` (~#5B21B6) tiene mejor contraste sobre fondo
/// blanco que `primary` para lecturas largas. Sólo el número comprado y
/// el QR quedan en negro — son los que el cliente lee al revisar y al
/// escanear, y se separan visualmente del resto del ticket.
const _kTicketBrandColor = AppTheme.primaryDark;

/// Replica visual del ticket térmico impreso por
/// `printer_bluetooth_datasource._buildTicketBytes`. La regla es: **misma
/// información y en el mismo orden** — sin agregados ni logos. Si algo
/// cambia en el ticket físico, este widget también debe cambiar.
///
/// Se envuelve en `RepaintBoundary` desde el llamador; acá solo definimos
/// la vista pura.
class TicketReceiptWidget extends StatelessWidget {
  const TicketReceiptWidget({
    required this.payload,
    super.key,
  });

  final TicketPayload payload;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (payload.copyKind != TicketCopyKind.original) ...[
              _CopyBanner(kind: payload.copyKind),
              const SizedBox(height: 16),
            ],
            _InfoBlock(payload: payload),
            const SizedBox(height: 20),
            const _DashedDivider(),
            const SizedBox(height: 14),
            _LinesTable(lines: payload.lines),
            const SizedBox(height: 14),
            const _DashedDivider(),
            const SizedBox(height: 18),
            _TotalRow(total: payload.total),
            const SizedBox(height: 18),
            const _SolidDivider(),
            const SizedBox(height: 16),
            const _CenteredNote(
              text: 'Boleto valido para 1 sorteo',
              bold: true,
            ),
            const SizedBox(height: 4),
            const _CenteredNote(text: 'Por favor revisar su compra'),
            const SizedBox(height: 4),
            const _CenteredNote(text: 'No se aceptan devoluciones'),
            const SizedBox(height: 20),
            _QrBlock(data: payload.toQrData()),
            if (payload.footer != null && payload.footer!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _CenteredNote(text: payload.footer!, bold: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.payload});
  final TicketPayload payload;

  @override
  Widget build(BuildContext context) {
    // La fecha del ticket y el sorteo se muestran en la hora LOCAL del
    // dispositivo (mismo criterio que el ticket físico, que llama
    // `.toLocal()` antes de formatear). Sin esto los DateTime UTC del
    // backend salían con offset UTC — un ticket a las 3pm Managua se veía
    // como sorteo de 9pm porque UTC-6 nunca se aplicaba.
    final saleDateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('h:mm a', 'en_US');
    final shortDateFmt = DateFormat('dd/MM');
    final saleLocal = payload.date.toLocal();
    final saleFormatted =
        '${saleDateFmt.format(saleLocal)} ${timeFmt.format(saleLocal).toLowerCase()}';

    String? drawFormatted;
    if (payload.drawAt != null) {
      final drawLocal = payload.drawAt!.toLocal();
      final now = DateTime.now();
      final sameDay = drawLocal.year == now.year &&
          drawLocal.month == now.month &&
          drawLocal.day == now.day;
      final drawTime = timeFmt.format(drawLocal).toLowerCase();
      drawFormatted =
          sameDay ? drawTime : '${shortDateFmt.format(drawLocal)} $drawTime';
    }

    // Cliente es una propiedad opcional cuyo LABEL siempre debe aparecer
    // (aunque el valor esté en blanco). El resto de campos siguen el orden
    // pedido por el negocio: Juego, Folio, Fecha, Sorteo, Cliente,
    // Vendedor, Puesto.
    final client = payload.client?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _InfoLine(text: 'Juego: ${payload.gameName}'),
        const SizedBox(height: 6),
        _InfoLine(text: 'Folio: ${payload.folio}'),
        const SizedBox(height: 6),
        _InfoLine(text: 'Fecha: $saleFormatted'),
        const SizedBox(height: 6),
        if (drawFormatted != null) ...[
          _InfoLine(text: 'Sorteo: $drawFormatted'),
          const SizedBox(height: 6),
        ],
        _InfoLine(text: 'Cliente: $client'),
        const SizedBox(height: 6),
        if (payload.seller != null && payload.seller!.isNotEmpty) ...[
          _InfoLine(text: 'Vendedor: ${payload.seller!}'),
          const SizedBox(height: 6),
        ],
        if (payload.salePoint != null && payload.salePoint!.isNotEmpty)
          _InfoLine(text: 'Puesto: ${payload.salePoint!}'),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _kTicketBrandColor,
        ),
      ),
    );
  }
}

class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.lines});
  final List<TicketLine> lines;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _kTicketBrandColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(flex: 4, child: Text('Apuesta', style: headerStyle)),
            Expanded(
              flex: 3,
              child: Text(
                'Monto',
                textAlign: TextAlign.right,
                style: headerStyle,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                'Premio',
                textAlign: TextAlign.right,
                style: headerStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < lines.length; i++) ...[
          if (lines[i].subGameName != null &&
              (i == 0 ||
                  lines[i - 1].subGameName != lines[i].subGameName)) ...[
            if (i > 0) const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '-- ${lines[i].subGameName!.toUpperCase()} --',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTicketBrandColor,
                ),
              ),
            ),
          ],
          _LineRow(line: lines[i]),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final TicketLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            // El número comprado se queda en NEGRO — es el dato crítico que
            // el cliente lee al revisar su boleto y visualmente lo separa
            // del resto (branding morado). Esta es la excepción explícita.
            child: Text(
              line.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              kAmountFormat.format(line.amount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kTicketBrandColor,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              kAmountFormat.format(line.prize),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kTicketBrandColor,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TOTAL: ${kCurrencyFormat.format(total)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _kTicketBrandColor,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote({required this.text, this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: _kTicketBrandColor,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 200,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _SolidDivider extends StatelessWidget {
  const _SolidDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: _kTicketBrandColor,
    );
  }
}

/// Banner que se pinta arriba del ticket cuando la venta ya no es la
/// original (reimpresión o reenvío por WhatsApp). Deja claro al cliente
/// que el papel/imagen que está viendo es una COPIA de una venta previa
/// y no un boleto nuevo con jugadas adicionales.
class _CopyBanner extends StatelessWidget {
  const _CopyBanner({required this.kind});
  final TicketCopyKind kind;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      TicketCopyKind.reprint => 'RECIBO DE COPIA',
      TicketCopyKind.resend => 'BOLETO REENVIADO',
      TicketCopyKind.original => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _kTicketBrandColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Divisor de guiones (`- - -`) que "encierra" la tabla de números arriba y
/// abajo. Guiones en vez de línea sólida porque replica visualmente el
/// carácter '-' que imprime la impresora térmica (ver `_dashedLine` en
/// `printer_bluetooth_datasource`).
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1.5,
              color: _kTicketBrandColor,
            ),
          ),
        );
      },
    );
  }
}
