import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/adaptive/app_layout_mode.dart';
import '../../../../core/ui/adaptive/app_layout_scope.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../auth/business_logic/cubit/auth_cubit.dart';
import '../../../auth/business_logic/cubit/auth_state.dart';
import '../../business_logic/cubit/settings_cubit.dart';
import '../../business_logic/cubit/settings_state.dart';
import '../layouts/settings_mobile_layout.dart';
import '../layouts/settings_tablet_layout.dart';
import 'settings_fields.dart';
import 'sign_out_section.dart';
import 'pending_sign_out_dialog.dart';

class SettingsWorkspace extends StatefulWidget {
  const SettingsWorkspace({super.key});
  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  final _fieldsKey = GlobalKey();
  late final TextEditingController _name, _subscription, _dropin;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsCubit>().state;
    _name = TextEditingController(text: state.name);
    _subscription = TextEditingController(text: state.subscriptionPrice);
    _dropin = TextEditingController(text: state.dropinPrice);
  }

  @override
  void dispose() {
    _name.dispose();
    _subscription.dispose();
    _dropin.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_confirming) return;
    _confirming = true;
    try {
      final settings = context.read<SettingsCubit>();
      if (settings.hasKnownPendingChanges &&
          !await PendingSignOutDialog.confirm(context)) {
        return;
      }
      if (mounted) await context.read<AuthCubit>().signOut();
    } finally {
      _confirming = false;
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (_name.text != state.name) _name.text = state.name;
          if (_subscription.text != state.subscriptionPrice) {
            _subscription.text = state.subscriptionPrice;
          }
          if (_dropin.text != state.dropinPrice) {
            _dropin.text = state.dropinPrice;
          }
        },
        builder: (context, state) {
          if (!state.ready && state.readFailure == null) {
            return const AppLoadingState();
          }
          final cubit = context.read<SettingsCubit>();
          final fields = SettingsFields(
            key: _fieldsKey,
            state: state,
            name: _name,
            subscriptionPrice: _subscription,
            dropinPrice: _dropin,
            onName: cubit.nameChanged,
            onSubscription: cubit.subscriptionPriceChanged,
            onDropin: cubit.dropinPriceChanged,
            onSave: cubit.submit,
            onReload: cubit.reloadDraft,
            onRetry: cubit.retry,
          );
          final account = BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) => SignOutSection(
              busy: auth.signingOut,
              onSignOut: _signOut,
              failure: auth.failure,
            ),
          );
          return AppLayoutScope.of(context) == AppLayoutMode.mobile
              ? SettingsMobileLayout(fields: fields, account: account)
              : SettingsTabletLayout(fields: fields, account: account);
        },
      );
}
