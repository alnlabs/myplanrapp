import 'package:flutter/material.dart';

/// Renders a value (typically a currency amount or number) that must always
/// stay on a single line.
///
/// Large values scale down to fit the available width instead of overflowing
/// or wrapping to a second line. Place it inside a bounded box (an [Expanded],
/// [Flexible], or a fixed-width parent) so the [FittedBox] has a width budget
/// to scale against.
class ValueText extends StatelessWidget {
  const ValueText(
    this.text, {
    super.key,
    this.style,
    this.alignment = Alignment.centerRight,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Alignment alignment;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        textAlign: textAlign,
      ),
    );
  }
}
