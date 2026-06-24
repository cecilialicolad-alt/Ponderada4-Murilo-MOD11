import 'package:flutter/material.dart';

class FallingFaceData {
  final int id;
  final double dx;
  final String asset;
  final double rotation;
  final int durationMs;

  const FallingFaceData({
    required this.id,
    required this.dx,
    required this.asset,
    required this.rotation,
    required this.durationMs,
  });
}

class FallingFace extends StatelessWidget {
  final FallingFaceData data;
  final double faceY;
  final VoidCallback onDone;

  const FallingFace({
    super.key,
    required this.data,
    required this.faceY,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: data.durationMs),
      onEnd: onDone,
      builder: (context, v, _) {
        final y = faceY + (1.4 - faceY) * v;
        return Align(
          alignment: Alignment(data.dx, y),
          child: Opacity(
            opacity: (1 - v).clamp(0.0, 1.0) * 0.6,
            child: Transform.rotate(
              angle: data.rotation * v,
              child: Transform.scale(
                scale: 0.75 * (1 - v * 0.35),
                child: Image.asset(data.asset, width: 90, height: 90),
              ),
            ),
          ),
        );
      },
    );
  }
}
