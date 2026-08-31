import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutoAdvanceNumberField extends StatefulWidget {
  const AutoAdvanceNumberField({
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.label,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final String? label;
  final bool autofocus;

  @override
  State<AutoAdvanceNumberField> createState() => _AutoAdvanceNumberFieldState();
}

class _AutoAdvanceNumberFieldState extends State<AutoAdvanceNumberField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (widget.controller.text.length == 2 && widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: '00',
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
