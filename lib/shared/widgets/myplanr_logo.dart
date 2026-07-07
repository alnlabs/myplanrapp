import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// MyPlanr brand mark — icon-only or icon with "planr" inside the badge.
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
      child: showWordmark ? _wordmark() : _iconOnly(),
    );
  }

  Widget _iconOnly() {
    return SvgPicture.asset(
      'assets/branding/myplanr_icon.svg',
      height: height,
    );
  }

  Widget _wordmark() {
    return SizedBox(
      height: height,
      width: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/branding/myplanr_logo.svg',
            fit: BoxFit.contain,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: height * 0.09,
            child: Text(
              'planr',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: height * 0.148,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
