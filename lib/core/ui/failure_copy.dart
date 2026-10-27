import '../errors/app_failure.dart';

abstract final class FailureCopy {
  static String message(AppFailure failure) {
    if (failure.code == 'local-confirmation') {
      return 'ماقدرناش نتأكد من تطبيق التغيير على الجهاز. التغيير ممكن يكون لسه في الانتظار.';
    }
    if (failure.code == 'initial-download') {
      return 'أول تحميل للحساب محتاج إنترنت. اتصل بالإنترنت وحاول تاني.';
    }
    return switch (failure.kind) {
      FailureKind.validation => 'راجع البيانات وحاول تاني.',
      FailureKind.permission =>
        'العملية اترفضت. راجع الحساب والبيانات وحاول تاني.',
      FailureKind.unauthenticated => 'سجّل الدخول تاني عشان تكمّل.',
      FailureKind.unavailable =>
        'مش قادرين نكمّل دلوقتي. راجع الاتصال وحاول تاني.',
      FailureKind.notFound => 'السجل مبقاش موجود. ارجع للقائمة وحدّث البيانات.',
      FailureKind.incompleteData =>
        'البيانات لسه مش كاملة. اتصل بالإنترنت وحدّثها قبل العملية دي.',
      FailureKind.tooLarge =>
        'الحذف الكامل أكبر من الحد المدعوم. مفيش بيانات اتحذفت.',
      FailureKind.conflict =>
        'في تعديل تاني لنفس العضو. استنى تطبيقه وجرب تاني.',
      FailureKind.unknown => 'حصلت مشكلة. حاول تاني.',
    };
  }
}
