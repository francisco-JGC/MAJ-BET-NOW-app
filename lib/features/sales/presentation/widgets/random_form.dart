import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';

class RandomFormResult {
  const RandomFormResult({required this.count, required this.amount});

  final int count;
  final int amount;
}

class RandomForm extends StatefulWidget {
  const RandomForm({required this.onSubmit, super.key});

  final void Function(RandomFormResult result) onSubmit;

  @override
  State<RandomForm> createState() => _RandomFormState();
}

class _RandomFormState extends State<RandomForm> {
  final _amountCtrl = TextEditingController();
  final _countCtrl = TextEditingController();

  final _amountFocus = FocusNode();
  final _countFocus = FocusNode();

  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _countCtrl.dispose();
    _amountFocus.dispose();
    _countFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountCtrl.text);
    final count = int.tryParse(_countCtrl.text);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Ingrese un monto mayor a 0');
      _amountFocus.requestFocus();
      return;
    }
    if (count == null || count < 1 || count > 100) {
      setState(() => _errorMessage = 'La cantidad debe estar entre 1 y 100');
      _countFocus.requestFocus();
      return;
    }

    widget.onSubmit(RandomFormResult(count: count, amount: amount));
    _amountCtrl.clear();
    _countCtrl.clear();
    setState(() => _errorMessage = null);
    _amountFocus.requestFocus();
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
            focusNode: _amountFocus,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Monto por número',
              prefixText: '$kCurrencySymbol ',
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _countFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _countCtrl,
            focusNode: _countFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Cantidad de números',
              hintText: '1 - 100',
            ),
            textInputAction: TextInputAction.done,
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
            icon: const Icon(Icons.casino),
            label: const Text('Generar aleatorios'),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
