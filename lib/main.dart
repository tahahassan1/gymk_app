import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/app_bootstrap.dart';
import 'app/di.dart';
import 'app/initialize_firebase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Cairo'], license);
  });
  runApp(
    AppBootstrap(
      initialize: initializeFirebase,
      readyBuilder: () {
        final dependencies = configureDependencies();
        return GymkApp(router: dependencies<GoRouter>());
      },
    ),
  );
}
