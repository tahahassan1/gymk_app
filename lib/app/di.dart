import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

/// App composition only. Future route/form Cubits use factories; tenant
/// repositories/projections will belong to captured-UID session scopes.
GetIt configureDependencies() {
  final dependencies = GetIt.asNewInstance();
  dependencies.registerFactory<GoRouter>(createAppRouter);
  return dependencies;
}
