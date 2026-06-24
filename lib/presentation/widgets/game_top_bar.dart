import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import '../../theme/app_theme.dart';

class GameTopBar extends StatelessWidget {
  final int level;
  final double xpProgress;

  final int gainTick;

  final int intoLevel;
  final int levelTarget;

  final VoidCallback onLevelLongPress;

  const GameTopBar({
    super.key,
    required this.level,
    required this.xpProgress,
    required this.gainTick,
    required this.intoLevel,
    required this.levelTarget,
    required this.onLevelLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onLongPress: onLevelLongPress,
          child: Text('N. $level', style: AppTheme.marker(26)),
        ),
        const SizedBox(width: 10),
        Expanded(child: _xpBar()),
        const SizedBox(width: 8),
        SizedBox(width: 34, child: _gainFeedback()),
      ],
    );
  }

  Widget _xpBar() {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        final h = w * 89 / 769;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: xpProgress.clamp(0.0, 1.0),
                  child: Image.asset(
                    A.levelBarFull,
                    width: w,
                    height: h,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Image.asset(
                A.levelBarFrame,
                width: w,
                height: h,
                fit: BoxFit.fill,
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '$intoLevel/$levelTarget',
                    style: AppTheme.hand(13, color: AppTheme.ink),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _gainFeedback() {
    if (gainTick == 0) return null;
    return TweenAnimationBuilder<double>(
      key: ValueKey(gainTick),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, v, _) => Transform.translate(
        offset: Offset(0, -14 * v),
        child: Opacity(
          opacity: (1 - v).clamp(0.0, 1.0),
          child: Text('+1', style: AppTheme.marker(18)),
        ),
      ),
    );
  }
}
