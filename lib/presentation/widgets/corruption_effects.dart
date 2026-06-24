import 'dart:math';
import 'package:flutter/material.dart';

import '../../state/game_state.dart';
import '../../theme/app_theme.dart';

class CorruptionEffects extends StatefulWidget {
  final Widget child;

  final double shake;

  final double tint;

  const CorruptionEffects({
    super.key,
    required this.child,
    this.shake = 1.5,
    this.tint = 0.0,
  });

  @override
  State<CorruptionEffects> createState() => _CorruptionEffectsState();
}

class _CorruptionEffectsState extends State<CorruptionEffects>
    with SingleTickerProviderStateMixin {
  final _game = GameState.instance;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _game.finalPhase;
    if (active && !_c.isAnimating) {
      _c.repeat();
    } else if (!active && _c.isAnimating) {
      _c.stop();
    }
    if (!active) return widget.child;

    final shaken = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * pi;
        final dx = (sin(t * 13) + sin(t * 7)) * 0.5 * widget.shake;
        final dy = (cos(t * 11) + sin(t * 5)) * 0.5 * widget.shake;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );

    if (widget.tint <= 0) return shaken;
    return Stack(
      children: [
        shaken,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: AppTheme.blood.withValues(alpha: widget.tint),
            ),
          ),
        ),
      ],
    );
  }
}
