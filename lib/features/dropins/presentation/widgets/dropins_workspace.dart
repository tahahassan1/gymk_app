import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/adaptive/app_layout_mode.dart';
import '../../../../core/ui/adaptive/app_layout_scope.dart';
import '../../../../core/ui/app_deletion_dialog.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/ui/date_resume_observer.dart';
import '../../business_logic/cubit/dropins_cubit.dart';
import '../../business_logic/cubit/dropins_state.dart';
import '../../business_logic/cubit/dropin_form_cubit.dart';
import '../../business_logic/cubit/dropin_form_state.dart';
import '../layouts/dropins_mobile_layout.dart';
import '../layouts/dropins_tablet_layout.dart';
import 'dropin_fields.dart';
import 'dropin_row.dart';
import 'dropin_edit_form.dart';
import 'dropin_day_controls.dart';

class DropinsWorkspace extends StatefulWidget {
  const DropinsWorkspace({super.key});
  @override
  State<DropinsWorkspace> createState() => _DropinsWorkspaceState();
}

class _DropinsWorkspaceState extends State<DropinsWorkspace> {
  final _entryKey = GlobalKey();
  late final TextEditingController _name, _amount;
  @override
  void initState() {
    super.initState();
    final state = context.read<DropinFormCubit>().state;
    _name = TextEditingController(text: state.name);
    _amount = TextEditingController(text: state.amount);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = context.read<DropinsCubit>();
    final form = context.read<DropinFormCubit>();
    return DateResumeObserver(
      onResume: () {
        list.refreshDate();
        form.refreshDate();
      },
      child: BlocListener<DropinFormCubit, DropinFormState>(
        listener: (context, state) {
          if (state.submission.applied) {
            form.startNext();
          }
          if (_name.text != form.state.name) _name.text = form.state.name;
          if (_amount.text != form.state.amount) {
            _amount.text = form.state.amount;
          }
        },
        child: BlocBuilder<DropinsCubit, DropinsState>(
          builder: (context, state) {
            final entry = BlocBuilder<DropinFormCubit, DropinFormState>(
              builder: (context, formState) => DropinFields(
                key: _entryKey,
                state: formState,
                name: _name,
                amount: _amount,
                onName: form.nameChanged,
                onAmount: form.amountChanged,
                onSave: form.submit,
                readOnly: !form.canEdit,
              ),
            );
            final controls = DropinDayControls(
              state: state,
              onDay: list.dayChanged,
              onToday: list.showToday,
              onRetry: list.retry,
            );
            final Widget rows = !state.ready && state.failure == null
                ? const SliverToBoxAdapter(child: AppLoadingState())
                : state.rows.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.complete
                            ? 'مفيش حصص مسجلة في اليوم ده'
                            : 'مفيش حصص في البيانات المتاحة لليوم ده',
                      ),
                    ),
                  )
                : SliverList.separated(
                    itemCount: state.rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = state.rows[index];
                      return DropinRow(
                        record: record,
                        onEdit: state.submission.busy
                            ? null
                            : () => DropinEditForm.show(
                                context,
                                list.repository,
                                list.clock,
                                record,
                              ),
                        onDelete: state.submission.busy
                            ? null
                            : () async {
                                final confirmed =
                                    await AppDeletionDialog.confirm(
                                      context,
                                      title: 'حذف الحصة؟',
                                      message: 'الحصة هتتحذف نهائيًا والمتحصلات هتتغير.',
                                    );
                                if (confirmed && context.mounted) {
                                  await list.delete(record);
                                }
                              },
                      );
                    },
                  );
            return AppLayoutScope.of(context) == AppLayoutMode.mobile
                ? DropinsMobileLayout(
                    entry: entry,
                    dayControls: controls,
                    rows: rows,
                  )
                : DropinsTabletLayout(
                    entry: entry,
                    dayControls: controls,
                    rows: rows,
                  );
          },
        ),
      ),
    );
  }
}
