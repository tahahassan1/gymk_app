import 'package:flutter/material.dart';

import '../../core/theme/app_geometry.dart';
import '../../core/ui/app_button.dart';
import '../../core/ui/app_text_field.dart';
import '../../l10n/app_localizations.dart';

/// Debug-only form harness. It does not save or manage gym data.
class FoundationPreviewForm extends StatefulWidget {
  const FoundationPreviewForm({super.key});

  @override
  State<FoundationPreviewForm> createState() => _FoundationPreviewFormState();
}

class _FoundationPreviewFormState extends State<FoundationPreviewForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: strings.name,
            controller: _name,
            validator: (value) => value == null || value.trim().isEmpty
                ? strings.requiredName
                : null,
          ),
          const SizedBox(height: AppGeometry.space16),
          AppTextField(
            label: strings.phone,
            controller: _phone,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppGeometry.space24),
          AppButton(
            label: strings.save,
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(strings.previewSaved)),
              );
            },
          ),
        ],
      ),
    );
  }
}
