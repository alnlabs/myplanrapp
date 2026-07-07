import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// MyPlanr brand mark — icon-only or horizontal wordmark.
class MyPlanrLogo extends StatelessWidget {
  const MyPlanrLogo({
    super.key,
    this.height = 72,
    this.showWordmark = false,
  });

  final double height;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MyPlanr',
      child: SvgPicture.asset(
        showWordmark
            ? 'assets/branding/myplanr_logo.svg'
            : 'assets/branding/myplanr_icon.svg',
        height: height,
      ),
    );
  }
}
