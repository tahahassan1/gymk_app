enum FailureKind {
  validation,
  permission,
  unauthenticated,
  unavailable,
  notFound,
  incompleteData,
  tooLarge,
  conflict,
  unknown,
}

/// Typed, nonlocalized failure. Presentation owns recovery copy.
final class AppFailure implements Exception {
  const AppFailure(this.kind, {this.code});

  final FailureKind kind;
  final String? code;

  @override
  String toString() => 'AppFailure(${kind.name}, $code)';
}
