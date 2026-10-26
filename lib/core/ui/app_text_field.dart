import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.textDirection,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textDirection: textDirection,
    keyboardType: keyboardType,
    validator: validator,
    onChanged: onChanged,
    autofocus: autofocus,
    decoration: InputDecoration(labelText: label),
  );
}
