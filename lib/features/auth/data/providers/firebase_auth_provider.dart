import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../app/session/data/providers/firebase_failure.dart';
import '../../../../app/session/data/providers/provider_stream.dart';
import '../../../../core/errors/app_failure.dart';
import '../models/auth_identity.dart';

/// Firebase and Google SDK objects never leave this provider.
final class FirebaseAuthProvider {
  FirebaseAuthProvider({required this.firebase, required this.google});

  final FirebaseAuth firebase;
  final GoogleSignIn google;
  Future<void>? _googleInitialization;

  Stream<AuthIdentity?> identities() => providerStream(
    firebase.authStateChanges(),
    (user) => user == null ? null : AuthIdentity(user.uid),
  );

  Future<SignInResult> signIn() async {
    try {
      await _initializeGoogle();
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AppFailure(FailureKind.permission, code: 'google-token');
      }
      await firebase.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      return SignInResult.signedIn;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return SignInResult.cancelled;
      }
      throw AppFailure(
        FailureKind.unavailable,
        code: 'google-${error.code.name}',
      );
    } catch (error) {
      throw firebaseFailure(error);
    }
  }

  Future<void> _initializeGoogle() async {
    try {
      await (_googleInitialization ??= google.initialize());
    } catch (_) {
      // A failed setup must not poison every later explicit retry.
      _googleInitialization = null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleInitialization != null) {
        await _googleInitialization;
        await google.signOut();
      }
      await firebase.signOut();
    } catch (error) {
      throw firebaseFailure(error);
    }
  }
}
