import 'package:flutter/material.dart';

import '../data/submission_state.dart';
import 'failure_copy.dart';

class SubmissionFeedback extends StatelessWidget {
  const SubmissionFeedback({super.key, required this.state});
  final SubmissionState state;
  @override
  Widget build(BuildContext context) => state.failure == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            FailureCopy.message(state.failure!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
}
