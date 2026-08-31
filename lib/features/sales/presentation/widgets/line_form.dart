import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';
import 'auto_advance_number_field.dart';

class LineFormResult {
  const LineFormResult({
    required this.start,
    required this.end,
    required this.amount,
  });

  final int start;
  final int end;
  final int amount;
}

class LineForm extends StatefulWidget {
  const LineForm({required this.onSubmit, super.key});

  final void Function(LineFormResult result) onSubmit;

  @override
  State<LineForm> createState() => _LineFormState();
}

class _LineFormState extends State<LineForm> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final _startFocus = FocusNode();
  final _endFocus = FocusNode();
  final _amountFocus = FocusNode();

  String? _errorMessage;

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _amountCtrl.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final start = int.tryParse(_startCtrl.text);
    final end = int.tryParse(_endCtrl.text);
    final amount = int.tryParse(_amountCtrl.text);

    if (start == null || start < 0 || start > 99) {
      setState(() => _errorMessage = 'Inicio inválido (00 - 99)');
      _startFocus.requestFocus();
      return;
    }
    if (end == null || end < 0 || end > 99) {
      setState(() => _errorMessage = 'Final inválido (00 - 99)');
      _endFocus.requestFocus();
      return;
    }
    if (end < start) {
      setState(() => _errorMessage = 'El final debe ser mayor o igual al inicio');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Ingrese un monto mayor a 0');
      _amountFocus.requestFocus();
      return;
    }

    widget.onSubmit(LineFormResult(start: start, end: end, amount: amount));
    _startCtrl.clear();
    _endCtrl.clear();
    _amountCtrl.clear();
    setState(() => _errorMessage = null);
    _startFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Registrar línea',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AutoAdvanceNumberField(
                  controller: _startCtrl,
                  focusNode: _startFocus,
                  nextFocusNode: _endFocus,
                  label: 'Inicio',
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 12),
              const Text('—', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: AutoAdvanceNumberField(
                  controller: _endCtrl,
                  focusNode: _endFocus,
                  nextFocusNode: _amountFocus,
                  label: 'Final',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            focusNode: _amountFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Monto por número',
              prefixText: '$kCurrencySymbol ',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar línea'),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
