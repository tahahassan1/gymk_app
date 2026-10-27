import '../models/auth_identity.dart';

abstract interface class AuthRepository {
  Stream<AuthIdentity?> watchIdentity();
  Future<SignInResult> signIn();
  Future<void> signOut();
}
