import 'package:flutter/material.dart';

import '../errors/app_failure.dart';
import 'failure_copy.dart';

class ReadNotice extends StatelessWidget {
  const ReadNotice({
    super.key,
    required this.complete,
    this.failure,
    this.onRetry,
    this.pending = false,
  });
  final bool complete;
  final bool pending;
  final AppFailure? failure;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    if (complete && failure == null && !pending) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failure != null
                ? FailureCopy.message(failure!)
                : !complete
                ? 'المعروض هو البيانات المتاحة؛ لسه مااتأكدناش إنها كاملة.'
                : 'الأرقام تشمل تغييرات في انتظار التأكيد.',
          ),
          if (failure != null && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('حاول تاني')),
        ],
      ),
    );
  }
}
