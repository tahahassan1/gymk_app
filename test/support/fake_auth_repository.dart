import 'dart:async';

import 'package:gymk_app/features/auth/data/models/auth_identity.dart';
import 'package:gymk_app/features/auth/data/repositories/auth_repository.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.current});
  AuthIdentity? current;
  final identities = StreamController<AuthIdentity?>.broadcast(sync: true);
  Completer<SignInResult>? pendingSignIn;
  int signIns = 0;
  int signOuts = 0;

  @override
  Stream<AuthIdentity?> watchIdentity() => Stream<AuthIdentity?>.multi((sink) {
    final subscription = identities.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.onCancel = subscription.cancel;
    sink.add(current);
  });
  void change(AuthIdentity? identity) {
    current = identity;
    identities.add(identity);
  }

  @override
  Future<SignInResult> signIn() {
    signIns++;
    return pendingSignIn?.future ?? Future.value(SignInResult.cancelled);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    change(null);
  }

  Future<void> close() => identities.close();
}
