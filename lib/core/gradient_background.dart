import 'package:flutter/material.dart';
import 'app_theme.dart';

enum GradientVariant { blue, red }

class GradientBackground extends StatelessWidget {
  final Widget child;
  final GradientVariant variant;

  const GradientBackground({
    super.key,
    required this.child,
    this.variant = GradientVariant.blue,
  });

  const GradientBackground.blue({
    super.key,
    required this.child,
  }) : variant = GradientVariant.blue;

  const GradientBackground.red({
    super.key,
    required this.child,
  }) : variant = GradientVariant.red;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    final topColor =
        variant == GradientVariant.blue ? tokens.blueTop : tokens.redTop;
    final bottomColor =
        variant == GradientVariant.blue ? tokens.blueBottom : tokens.redBottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: child,
    );
  }
}
