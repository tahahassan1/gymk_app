import 'package:flutter/material.dart';

import '../../../../core/ui/app_assets.dart';

class SignInBrand extends StatelessWidget {
  const SignInBrand({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    AppAssets.logo,
    width: 200,
    height: 200,
    fit: BoxFit.contain,
    semanticLabel: 'جيمك',
  );
}
