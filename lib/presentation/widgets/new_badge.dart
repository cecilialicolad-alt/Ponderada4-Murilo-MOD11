import 'dart:math';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class Badged extends StatefulWidget {
  final bool show;
  final Widget child;

  const Badged({super.key, required this.show, required this.child});

  @override
  State<Badged> createState() => _BadgedState();
}

class _BadgedState extends State<Badged> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = sin(_c.value * 2 * pi) * 2.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.blood,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
