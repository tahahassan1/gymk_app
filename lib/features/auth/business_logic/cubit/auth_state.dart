import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/models/auth_identity.dart';

const _keep = Object();

final class AuthState {
  const AuthState({
    this.identity,
    this.repository,
    this.initializing = true,
    this.loadingSession = false,
    this.signingIn = false,
    this.signingOut = false,
    this.failure,
    this.sessionEpoch = 0,
  });

  final AuthIdentity? identity;
  final GymRepository? repository;
  final bool initializing;
  final bool loadingSession;
  final bool signingIn;
  final bool signingOut;
  final AppFailure? failure;
  final int sessionEpoch;
  bool get ready => identity != null && repository != null && !loadingSession;

  AuthState copyWith({
    Object? identity = _keep,
    Object? repository = _keep,
    bool? initializing,
    bool? loadingSession,
    bool? signingIn,
    bool? signingOut,
    Object? failure = _keep,
    int? sessionEpoch,
  }) => AuthState(
    identity: identical(identity, _keep)
        ? this.identity
        : identity as AuthIdentity?,
    repository: identical(repository, _keep)
        ? this.repository
        : repository as GymRepository?,
    initializing: initializing ?? this.initializing,
    loadingSession: loadingSession ?? this.loadingSession,
    signingIn: signingIn ?? this.signingIn,
    signingOut: signingOut ?? this.signingOut,
    failure: identical(failure, _keep) ? this.failure : failure as AppFailure?,
    sessionEpoch: sessionEpoch ?? this.sessionEpoch,
  );
}
