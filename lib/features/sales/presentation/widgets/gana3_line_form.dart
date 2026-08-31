import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';

class Gana3LineResult {
  const Gana3LineResult({
    required this.start,
    required this.end,
    required this.amount,
    required this.isExact,
  });

  final int start;
  final int end;
  final int amount;
  final bool isExact;
}

class Gana3LineForm extends StatefulWidget {
  const Gana3LineForm({required this.onSubmit, super.key});

  final void Function(Gana3LineResult) onSubmit;

  @override
  State<Gana3LineForm> createState() => _Gana3LineFormState();
}

class _Gana3LineFormState extends State<Gana3LineForm> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isEasy = false;
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

    if (start == null || start < 0 || start > 999) {
      setState(() => _error = 'Inicio inválido (000 - 999)');
      return;
    }
    if (end == null || end < 0 || end > 999) {
      setState(() => _error = 'Final inválido (000 - 999)');
      return;
    }
    if (end < start) {
      setState(() => _error = 'El final debe ser mayor o igual al inicio');
      return;
    }
    if (amount == null || amount < 1 || amount > 999) {
      setState(() => _error = 'Monto inválido (1 - 999)');
      return;
    }
    widget.onSubmit(
      Gana3LineResult(
        start: start,
        end: end,
        amount: amount,
        isExact: !_isEasy,
      ),
    );
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
                    LengthLimitingTextInputFormatter(3),
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
                    LengthLimitingTextInputFormatter(3),
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
          Row(
            children: [
              Checkbox(
                value: _isEasy,
                onChanged: (v) => setState(() => _isEasy = v ?? false),
              ),
              const Text('Fácil'),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
