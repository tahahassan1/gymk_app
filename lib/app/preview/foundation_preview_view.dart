import 'package:flutter/material.dart';

import '../../core/theme/app_geometry.dart';
import '../../core/ui/app_assets.dart';
import '../../core/ui/app_button.dart';
import '../../core/ui/app_deletion_dialog.dart';
import '../../core/ui/app_feedback.dart';
import '../../core/ui/app_form_host.dart';
import '../../core/ui/app_formatters.dart';
import '../../core/ui/app_loading_state.dart';
import '../../core/ui/app_status_chip.dart';
import '../../l10n/app_localizations.dart';
import 'foundation_preview_form.dart';

/// Direct debug route only; no developer controls appear in product navigation.
class FoundationPreviewView extends StatelessWidget {
  const FoundationPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.previewTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppGeometry.formWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppGeometry.space24),
              children: [
                Image.asset(
                  AppAssets.logo,
                  height: 120,
                  fit: BoxFit.contain,
                  semanticLabel: strings.appName,
                ),
                const SizedBox(height: AppGeometry.space16),
                Text(strings.previewDescription),
                const SizedBox(height: AppGeometry.space16),
                Wrap(
                  spacing: AppGeometry.space8,
                  runSpacing: AppGeometry.space8,
                  children: [
                    AppStatusChip(
                      label: strings.active,
                      tone: AppStatusTone.success,
                    ),
                    AppStatusChip(
                      label: strings.expiring,
                      tone: AppStatusTone.warning,
                    ),
                    AppStatusChip(
                      label: strings.expired,
                      tone: AppStatusTone.danger,
                    ),
                    AppStatusChip(
                      label: strings.noSubscription,
                      tone: AppStatusTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppGeometry.space24),
                AppButton(
                  label: strings.previewForm,
                  onPressed: () => AppFormHost.show<void>(
                    context,
                    title: strings.previewForm,
                    builder: (_) => const FoundationPreviewForm(),
                  ),
                ),
                const SizedBox(height: AppGeometry.space16),
                AppButton(
                  label: strings.previewDelete,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => AppDeletionDialog.confirm(
                    context,
                    title: strings.previewDeleteTitle,
                    message: strings.previewDeleteMessage,
                  ),
                ),
                const SizedBox(height: AppGeometry.space16),
                OutlinedButton.icon(
                  onPressed: () => showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(strings.chooseDate),
                ),
                Text(
                  AppFormatters.date(DateTime(2026, 10, 27)),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppGeometry.space24),
                const AppLoadingState(),
                const SizedBox(height: AppGeometry.space24),
                SizedBox(
                  height: 300,
                  child: AppFeedback(
                    title: strings.unavailableTitle,
                    message: strings.previewFeedback,
                    actionLabel: strings.retry,
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
