import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';

/// Bottom sheet para agregar de un golpe todos los pares (dígito repetido)
/// de un juego de 2, 3 o 4 dígitos: 00/11/…/99, 000/111/…/999, etc.
class PairsForm extends StatefulWidget {
  const PairsForm({
    required this.digits,
    required this.onSubmit,
    super.key,
  });

  /// Número de dígitos del juego (2, 3 o 4).
  final int digits;

  /// Llamado al confirmar; el parent cierra el sheet y agrega al carrito.
  final void Function(int amount) onSubmit;

  @override
  State<PairsForm> createState() => _PairsFormState();
}

class _PairsFormState extends State<PairsForm> {
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null || amount < 1 || amount > 999) {
      setState(() => _errorMessage = 'Ingrese un monto válido (1 - 999)');
      _amountFocus.requestFocus();
      return;
    }
    setState(() => _errorMessage = null);
    widget.onSubmit(amount);
  }

  @override
  Widget build(BuildContext context) {
    final pairLabels =
        List.generate(10, (i) => i.toString() * widget.digits);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Todos los pares',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: pairLabels
                .map(
                  (label) => Chip(
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            focusNode: _amountFocus,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Monto por número',
              prefixText: '$kCurrencySymbol ',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.apps),
            label: const Text('Agregar todos los pares'),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
