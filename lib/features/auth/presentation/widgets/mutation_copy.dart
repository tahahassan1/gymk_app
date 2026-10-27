import '../../../../core/data/mutation_registry.dart';

abstract final class MutationCopy {
  static String status(MutationNotice notice) => switch (notice.stage) {
    MutationStage.submitted => 'جاري تطبيق التغيير. لسه مش مؤكد على الجهاز.',
    MutationStage.locallyApplied =>
      'اتطبق على الجهاز. في انتظار التأكيد من السحابة.',
    MutationStage.acknowledged => 'التغيير اتأكد من السحابة.',
    MutationStage.rejected => 'التغيير اترفض. راجع البيانات الحالية.',
  };
  static String action(MutationNotice notice) {
    final action = switch (notice.action) {
      MutationAction.saveMember => 'حفظ بيانات عضو',
      MutationAction.saveSubscription => 'حفظ اشتراك',
      MutationAction.deleteSubscription => 'حذف اشتراك',
      MutationAction.saveDropin => 'حفظ حصة',
      MutationAction.deleteDropin => 'حذف حصة',
      MutationAction.saveSettings => 'حفظ الإعدادات',
      MutationAction.deleteMember => 'حذف عضو واشتراكاته',
    };
    return notice.targetName == null ? action : '$action: ${notice.targetName}';
  }
}
