import 'package:flutter/material.dart';

import '../../../../core/theme/app_geometry.dart';
import '../widgets/sign_in_brand.dart';

class SignInTabletLayout extends StatelessWidget {
  const SignInTabletLayout({super.key, required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Row(
          children: [
            const Expanded(child: SignInBrand()),
            const SizedBox(width: AppGeometry.space32),
            Expanded(flex: 2, child: form),
          ],
        ),
      ),
    ),
  );
}
