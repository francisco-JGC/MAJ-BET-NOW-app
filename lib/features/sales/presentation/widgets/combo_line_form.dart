import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';

class ComboLineResult {
  const ComboLineResult({
    required this.start,
    required this.end,
    required this.amount,
  });

  final int start;
  final int end;
  final int amount;
}

class ComboLineForm extends StatefulWidget {
  const ComboLineForm({required this.onSubmit, super.key});

  final void Function(ComboLineResult) onSubmit;

  @override
  State<ComboLineForm> createState() => _ComboLineFormState();
}

class _ComboLineFormState extends State<ComboLineForm> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final start = int.tryParse(_startCtrl.text);
    final end = int.tryParse(_endCtrl.text);
    final amount = int.tryParse(_amountCtrl.text);

    if (start == null || start < 0 || start > 9999) {
      setState(() => _error = 'Inicio inválido (0000 - 9999)');
      return;
    }
    if (end == null || end < 0 || end > 9999) {
      setState(() => _error = 'Final inválido (0000 - 9999)');
      return;
    }
    if (end < start) {
      setState(() => _error = 'El final debe ser mayor o igual al inicio');
      return;
    }
    if (end - start > 200) {
      setState(() => _error = 'Rango demasiado grande (máx. 200 números)');
      return;
    }
    if (amount == null || amount < 1 || amount > 999) {
      setState(() => _error = 'Monto inválido (1 - 999)');
      return;
    }
    widget.onSubmit(ComboLineResult(start: start, end: end, amount: amount));
    _startCtrl.clear();
    _endCtrl.clear();
    _amountCtrl.clear();
    setState(() => _error = null);
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
                child: TextField(
                  controller: _startCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(labelText: 'Inicio'),
                ),
              ),
              const SizedBox(width: 12),
              const Text('—'),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(labelText: 'Final'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              labelText: 'Monto por número',
              prefixText: '$kCurrencySymbol ',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
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
