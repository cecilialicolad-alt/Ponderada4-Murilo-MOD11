import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FloatingFala extends StatelessWidget {
  final String text;
  final double t;

  const FloatingFala({super.key, required this.text, required this.t});

  @override
  Widget build(BuildContext context) {
    final pop = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
    final scale = 0.7 + 0.3 * pop;
    final fade = t < 0.5 ? 1.0 : (1 - (t - 0.5) / 0.5).clamp(0.0, 1.0);
    final dy = -12 * t;
    return Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: scale,
          child: Text(text, style: AppTheme.marker(32)),
        ),
      ),
    );
  }
}
