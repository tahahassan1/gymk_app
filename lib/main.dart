import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app_bootstrap.dart';
import 'app/app_runtime.dart';
import 'app/di.dart';
import 'app/initialize_firebase.dart';
import 'core/time/clock.dart';
import 'features/auth/business_logic/cubit/auth_cubit.dart';
import 'features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'features/members/business_logic/cubit/members_cubit.dart';

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
        return AppRuntime(
          auth: dependencies<AuthCubit>(),
          clock: dependencies<Clock>(),
          createMembers: (repository) =>
              dependencies<MembersCubit>(param1: repository),
          createFeedback: (repository) =>
              dependencies<MutationFeedbackCubit>(param1: repository),
        );
      },
    ),
  );
}
