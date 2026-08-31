import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';

class ComboRandomResult {
  const ComboRandomResult({required this.count, required this.amount});

  final int count;
  final int amount;
}

class ComboRandomForm extends StatefulWidget {
  const ComboRandomForm({required this.onSubmit, super.key});

  final void Function(ComboRandomResult) onSubmit;

  @override
  State<ComboRandomForm> createState() => _ComboRandomFormState();
}

class _ComboRandomFormState extends State<ComboRandomForm> {
  final _amountCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountCtrl.text);
    final count = int.tryParse(_countCtrl.text);
    if (amount == null || amount < 1 || amount > 999) {
      setState(() => _error = 'Monto inválido (1 - 999)');
      return;
    }
    if (count == null || count < 1 || count > 100) {
      setState(() => _error = 'Cantidad entre 1 y 100');
      return;
    }
    widget.onSubmit(ComboRandomResult(count: count, amount: amount));
    _amountCtrl.clear();
    _countCtrl.clear();
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
                  'Registrar aleatorio',
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
          const SizedBox(height: 12),
          TextField(
            controller: _countCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              labelText: 'Cantidad de números',
              hintText: '1 - 100',
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
            icon: const Icon(Icons.casino),
            label: const Text('Generar aleatorios'),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
