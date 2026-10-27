import 'package:flutter/material.dart';

import '../../../../core/theme/app_geometry.dart';
import '../widgets/sign_in_brand.dart';

class SignInMobileLayout extends StatelessWidget {
  const SignInMobileLayout({super.key, required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SignInBrand(),
            const SizedBox(height: AppGeometry.space24),
            form,
          ],
        ),
      ),
    ),
  );
}
