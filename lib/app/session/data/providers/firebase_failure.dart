import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/app_failure.dart';

AppFailure firebaseFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is FirebaseException) {
    final kind = switch (error.code) {
      'permission-denied' => FailureKind.permission,
      'unauthenticated' => FailureKind.unauthenticated,
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => FailureKind.unavailable,
      'not-found' => FailureKind.notFound,
      'invalid-argument' => FailureKind.validation,
      'aborted' || 'already-exists' => FailureKind.conflict,
      _ => FailureKind.unknown,
    };
    return AppFailure(kind, code: error.code);
  }
  if (error is ArgumentError ||
      error is FormatException ||
      error is TypeError) {
    return const AppFailure(FailureKind.validation, code: 'malformed-record');
  }
  return const AppFailure(FailureKind.unknown);
}
