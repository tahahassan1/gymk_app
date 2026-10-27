import '../../../../core/data/model_validation.dart';

enum SignInResult { signedIn, cancelled }

final class AuthIdentity {
  AuthIdentity(String uid) : uid = documentId(uid);
  final String uid;
}
