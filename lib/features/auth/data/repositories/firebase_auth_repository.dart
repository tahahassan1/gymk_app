import '../models/auth_identity.dart';
import '../providers/firebase_auth_provider.dart';
import 'auth_repository.dart';

final class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this.provider);
  final FirebaseAuthProvider provider;

  @override
  Stream<AuthIdentity?> watchIdentity() => provider.identities();
  @override
  Future<SignInResult> signIn() => provider.signIn();
  @override
  Future<void> signOut() => provider.signOut();
}
