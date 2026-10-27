import '../errors/app_failure.dart';
import '../money/amount_policy.dart';

String documentId(String value) {
  if (value.isEmpty || value.contains('/') || value == '.' || value == '..') {
    throw const AppFailure(FailureKind.validation, code: 'document-id');
  }
  return value;
}

String requiredName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw const AppFailure(FailureKind.validation, code: 'name');
  }
  return trimmed;
}

String? optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

int validatedAmount(int value, AmountPurpose purpose) {
  final failure = AmountPolicy.validateMinorUnits(value, purpose: purpose);
  if (failure != null) {
    throw AppFailure(FailureKind.validation, code: failure.name);
  }
  return value;
}
