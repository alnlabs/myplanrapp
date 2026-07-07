import 'package:flutter/material.dart';

import '../../features/debug/logs_access_gate.dart';

/// Wraps [child] with a hidden multi-tap gesture. After [tapsRequired] quick
/// taps, prompts for the diagnostic logs PIN before opening the logs screen.
class SecretTap extends StatefulWidget {
  const SecretTap({
    super.key,
    required this.child,
    this.tapsRequired = 7,
  });

  final Widget child;
  final int tapsRequired;

  @override
  State<SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<SecretTap> {
  int _count = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap) > const Duration(seconds: 2)) {
      _count = 0;
    }
    _lastTap = now;
    _count++;
    if (_count >= widget.tapsRequired) {
      _count = 0;
      LogsAccessGate.openIfAuthorized(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onTap,
      child: widget.child,
    );
  }
}
