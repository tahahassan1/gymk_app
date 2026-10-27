import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/auth/business_logic/cubit/auth_cubit.dart';

final class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthCubit auth) {
    _subscription = auth.stream.listen((_) {
      if (!_disposed) notifyListeners();
    });
  }
  late final StreamSubscription<Object?> _subscription;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
