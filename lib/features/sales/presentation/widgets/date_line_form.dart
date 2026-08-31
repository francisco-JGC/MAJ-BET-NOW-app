import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/entities/date_bet.dart';

class DateLineResult {
  const DateLineResult({
    required this.dayStart,
    required this.dayEnd,
    required this.month,
    required this.amount,
  });

  final int dayStart;
  final int dayEnd;
  final int month;
  final int amount;
}

class DateLineForm extends StatefulWidget {
  const DateLineForm({required this.onSubmit, super.key});

  final void Function(DateLineResult) onSubmit;

  @override
  State<DateLineForm> createState() => _DateLineFormState();
}

class _DateLineFormState extends State<DateLineForm> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late int _month = DateTime.now().month;
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
    if (start == null || start < 1 || start > 31) {
      setState(() => _error = 'Día inicio inválido (01 - 31)');
      return;
    }
    if (end == null || end < 1 || end > 31) {
      setState(() => _error = 'Día final inválido (01 - 31)');
      return;
    }
    if (end < start) {
      setState(() => _error = 'El día final debe ser mayor o igual al inicio');
      return;
    }
    if (amount == null || amount < 1 || amount > 999) {
      setState(() => _error = 'Monto inválido (1 - 999)');
      return;
    }
    widget.onSubmit(DateLineResult(
      dayStart: start,
      dayEnd: end,
      month: _month,
      amount: amount,
    ));
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
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Día inicio'),
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
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Día final'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _month,
            decoration: const InputDecoration(labelText: 'Mes'),
            items: [
              for (var i = 1; i <= 12; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(kMonthAbbreviations[i - 1]),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _month = v);
            },
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
