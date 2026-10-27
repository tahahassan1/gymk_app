import 'package:flutter/widgets.dart';

class DateResumeObserver extends StatefulWidget {
  const DateResumeObserver({
    super.key,
    required this.onResume,
    required this.child,
  });
  final VoidCallback onResume;
  final Widget child;
  @override
  State<DateResumeObserver> createState() => _DateResumeObserverState();
}

class _DateResumeObserverState extends State<DateResumeObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
