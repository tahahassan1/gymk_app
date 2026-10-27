import 'package:flutter/material.dart';

import '../time/date_only.dart';
import 'app_formatters.dart';

class AppMonthPicker extends StatefulWidget {
  const AppMonthPicker({super.key, required this.value});
  final DateOnly value;
  static Future<DateOnly?> show(BuildContext context, DateOnly value) =>
      showDialog<DateOnly>(
        context: context,
        builder: (_) => AppMonthPicker(value: value),
      );
  @override
  State<AppMonthPicker> createState() => _AppMonthPickerState();
}

class _AppMonthPickerState extends State<AppMonthPicker> {
  late int _year = widget.value.year;
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('اختار الشهر'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'السنة السابقة',
                onPressed: _year > 1 ? () => setState(() => _year--) : null,
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(child: Text('$_year', textAlign: TextAlign.center)),
              IconButton(
                tooltip: 'السنة التالية',
                onPressed: _year < 9999 ? () => setState(() => _year++) : null,
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var month = 1; month <= 12; month++)
                SizedBox(
                  width: 132,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(DateOnly(_year, month, 1)),
                    child: Text(
                      AppFormatters.month(DateOnly(_year, month, 1)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('رجوع'),
      ),
    ],
  );
}
