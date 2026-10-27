import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../settings/data/models/gym_settings.dart';
import '../../data/models/auth_identity.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.authRepository,
    required this.createGymRepository,
    required this.initialSettings,
    this.initialReadTimeout = const Duration(seconds: 15),
  }) : super(const AuthState()) {
    _identitySubscription = authRepository.watchIdentity().listen(
      (identity) {
        unawaited(_switchIdentity(identity));
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              initializing: false,
              signingIn: false,
              failure: _failure(error),
            ),
          );
        }
      },
    );
  }

  final AuthRepository authRepository;
  final GymRepository Function(String uid) createGymRepository;
  final GymSettings initialSettings;
  final Duration initialReadTimeout;
  late final StreamSubscription<AuthIdentity?> _identitySubscription;
  GymRepository? _ownedRepository;
  String? _targetUid;
  bool _receivedIdentity = false;
  int _generation = 0;

  Future<void> signIn() async {
    if (state.initializing ||
        state.signingIn ||
        state.loadingSession ||
        isClosed) {
      return;
    }
    emit(state.copyWith(signingIn: true, failure: null));
    try {
      final result = await authRepository.signIn();
      if (!isClosed && result == SignInResult.cancelled) {
        emit(state.copyWith(signingIn: false));
      }
      // A successful sign-in is completed by the authoritative identity stream.
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(signingIn: false, failure: _failure(error)));
      }
    }
  }

  Future<void> signOut() async {
    if (state.signingOut || isClosed) return;
    emit(state.copyWith(signingOut: true, failure: null));
    try {
      await authRepository.signOut();
      if (!isClosed && state.identity == null && state.signingOut) {
        emit(state.copyWith(signingOut: false));
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(signingOut: false, failure: _failure(error)));
      }
    }
  }

  Future<void> retrySession() => _switchIdentity(state.identity, force: true);

  Future<void> _switchIdentity(
    AuthIdentity? identity, {
    bool force = false,
  }) async {
    if (isClosed) return;
    if (!force && _receivedIdentity && identity?.uid == _targetUid) return;
    _receivedIdentity = true;
    _targetUid = identity?.uid;
    final generation = ++_generation;
    final previous = _ownedRepository;
    _ownedRepository = null;
    // Clear the previous tenant synchronously, before awaiting any teardown/read.
    emit(
      AuthState(
        identity: identity,
        initializing: false,
        loadingSession: identity != null,
        sessionEpoch: generation,
      ),
    );
    try {
      if (previous != null) await previous.close();
      if (isClosed || generation != _generation || identity == null) return;
      final repository = createGymRepository(identity.uid);
      _ownedRepository = repository;
      final settings = await repository
          .watchSettings()
          .firstWhere(
            (snapshot) => snapshot.data != null || snapshot.isComplete,
          )
          .timeout(initialReadTimeout);
      if (isClosed || generation != _generation) return;
      if (settings.data == null) {
        await repository.ensureInitialSettings(initialSettings);
        if (isClosed || generation != _generation) return;
        await repository
            .watchSettings()
            .firstWhere((snapshot) => snapshot.data != null)
            .timeout(initialReadTimeout);
      }
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          repository: repository,
          loadingSession: false,
          failure: null,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      final failedRepository = _ownedRepository;
      _ownedRepository = null;
      if (failedRepository != null) await failedRepository.close();
      if (!isClosed && generation == _generation) {
        emit(
          state.copyWith(
            repository: null,
            loadingSession: false,
            failure: _failure(error),
          ),
        );
      }
    }
  }

  static AppFailure _failure(Object error) => error is AppFailure
      ? error
      : error is TimeoutException
      ? const AppFailure(FailureKind.unavailable, code: 'initial-download')
      : const AppFailure(FailureKind.unknown);

  @override
  Future<void> close() async {
    _generation++;
    await _identitySubscription.cancel();
    await _ownedRepository?.close();
    _ownedRepository = null;
    return super.close();
  }
}
