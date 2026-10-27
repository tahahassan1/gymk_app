import 'package:flutter/material.dart';

class PendingSignOutDialog extends StatelessWidget {
  const PendingSignOutDialog({super.key});
  static Future<bool> confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const PendingSignOutDialog(),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('في تغييرات لسه في الانتظار'),
    content: const Text(
      'الخروج مش معناه إن التغييرات وصلت للحساب. الأفضل تفضل داخل لحد تأكيدها. لو خرجت دلوقتي مش هنمسح البيانات المحفوظة على الجهاز.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('أفضل داخل'),
      ),
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('خروج دلوقتي'),
      ),
    ],
  );
}
