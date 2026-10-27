import 'package:flutter/material.dart';

import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/read_notice.dart';
import '../../business_logic/cubit/members_state.dart';

class MembersControls extends StatelessWidget {
  const MembersControls({
    super.key,
    required this.state,
    required this.search,
    required this.onSearch,
    required this.onFilter,
    required this.onAdd,
    required this.onSubscribe,
    required this.onRetry,
  });
  final MembersState state;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<MemberFilter> onFilter;
  final VoidCallback onAdd;
  final VoidCallback onSubscribe;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('الأعضاء', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      AppTextField(
        label: 'ابحث بالاسم',
        controller: search,
        onChanged: onSearch,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final filter in MemberFilter.values)
            ChoiceChip(
              label: Text(switch (filter) {
                MemberFilter.all => 'الكل',
                MemberFilter.active => 'ساري',
                MemberFilter.expiringSoon => 'قرب يخلص',
                MemberFilter.expired => 'منتهي',
              }),
              selected: state.filter == filter,
              onSelected: (_) => onFilter(filter),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          AppButton(label: 'اشتراك جديد', onPressed: onSubscribe),
          AppButton(
            label: 'إضافة عضو',
            variant: AppButtonVariant.secondary,
            onPressed: onAdd,
          ),
        ],
      ),
      ReadNotice(
        complete: state.complete,
        failure: state.membersFailure ?? state.coverageFailure,
        onRetry: onRetry,
      ),
    ],
  );
}
