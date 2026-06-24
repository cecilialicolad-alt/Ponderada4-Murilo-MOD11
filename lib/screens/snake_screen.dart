import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../data/asset_paths.dart';
import '../data/dialogue.dart';
import '../presentation/widgets/corruption_effects.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen>
    with TickerProviderStateMixin {
  static const int _cols = 10;
  static const int _rows = 14;
  static const int _baseIntervalMs = 200;
  static const int _minIntervalMs = 130;

  final _game = GameState.instance;
  final _rng = Random();

  late final AnimationController _applePulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  late final Ticker _loop;
  Duration _lastElapsed = Duration.zero;
  double _stepAcc = 0;
  double _t = 0;

  List<Point<int>> _snake = [];
  List<Point<int>> _prevSnake = [];
  Point<int> _dir = const Point(1, 0);
  Point<int> _nextDir = const Point(1, 0);
  Point<int> _apple = const Point(0, 0);
  int _score = 0;
  int _lives = 2;
  int _intervalMs = _baseIntervalMs;
  bool _dead = false;
  String? _deathMsg;

  @override
  void initState() {
    super.initState();
    _loop = createTicker(_onLoop);
    _reset();
  }

  @override
  void dispose() {
    _loop.dispose();
    _applePulse.dispose();
    super.dispose();
  }

  void _reset() {
    _snake = [const Point(4, 7), const Point(3, 7), const Point(2, 7)];
    _prevSnake = List<Point<int>>.from(_snake);
    _dir = const Point(1, 0);
    _nextDir = const Point(1, 0);
    _score = 0;
    _lives = 2;
    _intervalMs = _baseIntervalMs;
    _dead = false;
    _deathMsg = null;
    _stepAcc = 0;
    _t = 0;
    _lastElapsed = Duration.zero;
    _placeApple();
    if (!_loop.isActive) _loop.start();
    setState(() {});
  }

  void _onLoop(Duration elapsed) {
    if (_dead) return;
    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _stepAcc += dt;
    var stepSec = _intervalMs / 1000.0;
    while (_stepAcc >= stepSec) {
      _stepAcc -= stepSec;
      _step();
      if (_dead) return;
      stepSec = _intervalMs / 1000.0;
    }
    setState(() => _t = (_stepAcc / stepSec).clamp(0.0, 1.0));
  }

  void _placeApple() {
    final free = <Point<int>>[];
    for (var x = 0; x < _cols; x++) {
      for (var y = 0; y < _rows; y++) {
        final p = Point(x, y);
        if (!_snake.contains(p)) free.add(p);
      }
    }
    if (free.isNotEmpty) _apple = free[_rng.nextInt(free.length)];
  }

  void _setDir(Point<int> d) {
    if (d.x == -_dir.x && d.y == -_dir.y) return;
    _nextDir = d;
  }

  void _step() {
    _prevSnake = List<Point<int>>.from(_snake);
    _dir = _nextDir;
    final head = _snake.first;
    final newHead = Point(head.x + _dir.x, head.y + _dir.y);

    final hitWall =
        newHead.x < 0 ||
        newHead.x >= _cols ||
        newHead.y < 0 ||
        newHead.y >= _rows;
    if (hitWall || _snake.contains(newHead)) {
      _loseLife();
      return;
    }

    _snake.insert(0, newHead);
    if (newHead == _apple) {
      _score += 15;
      HapticFeedback.lightImpact();
      _placeApple();
      _intervalMs = max(_minIntervalMs, _baseIntervalMs - (_score ~/ 15) * 6);
    } else {
      _snake.removeLast();
    }
  }

  void _loseLife() {
    _lives--;
    HapticFeedback.mediumImpact();
    if (_lives <= 0) {
      _die();
      return;
    }
    _snake = [const Point(4, 7), const Point(3, 7), const Point(2, 7)];
    _prevSnake = List<Point<int>>.from(_snake);
    _dir = const Point(1, 0);
    _nextDir = const Point(1, 0);
    _stepAcc = 0;
    _t = 0;
  }

  void _die() {
    _dead = true;
    _loop.stop();
    HapticFeedback.heavyImpact();
    _deathMsg = Dialogue.derrota(_game.dreadStage);
    _game.addMurilos(_score);
    _game.startCooldown(2);
    setState(() {});
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() > v.dy.abs()) {
      _setDir(v.dx > 0 ? const Point(1, 0) : const Point(-1, 0));
    } else {
      _setDir(v.dy > 0 ? const Point(0, 1) : const Point(0, -1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        foregroundColor: AppTheme.ink,
        centerTitle: true,
        title: Text('COBRA MURILO', style: AppTheme.marker(20)),
      ),
      body: CorruptionEffects(
        shake: 3,
        tint: 0.13,
        child: Stack(
          children: [
            GestureDetector(
              onPanEnd: _onSwipe,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_score),
                          tween: Tween(begin: 1.4, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          builder: (context, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: Text(
                            'Murilos: $_score',
                            style: AppTheme.marker(24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '❤' * _lives,
                          style: AppTheme.marker(20, color: AppTheme.blood),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _cols / _rows,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final cell = c.maxWidth / _cols;
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F0E8),
                                border: Border.all(
                                  color: AppTheme.ink,
                                  width: 3,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _GridPainter(_cols, _rows),
                                    ),
                                  ),
                                  _appleWidget(cell),
                                  for (var i = _snake.length - 1; i >= 0; i--)
                                    _segmentInterp(i, cell, isHead: i == 0),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'deslize para virar',
                      style: AppTheme.hand(16, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
            if (_dead) _deathOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _segmentInterp(int i, double cell, {required bool isHead}) {
    final curr = _snake[i];
    final prev = i < _prevSnake.length ? _prevSnake[i] : curr;
    final x = prev.x + (curr.x - prev.x) * _t;
    final y = prev.y + (curr.y - prev.y) * _t;
    final size = cell * (isHead ? 2.05 : 1.9);
    final offset = (size - cell) / 2;
    return Positioned(
      left: x * cell - offset,
      top: y * cell - offset,
      width: size,
      height: size,
      child: Image.asset(A.snakeHead, fit: BoxFit.contain),
    );
  }

  Widget _appleWidget(double cell) {
    final size = cell * 1.3;
    final offset = (size - cell) / 2;
    return Positioned(
      left: _apple.x * cell - offset,
      top: _apple.y * cell - offset,
      width: size,
      height: size,
      child: ScaleTransition(
        scale: Tween(begin: 0.82, end: 1.08).animate(_applePulse),
        child: Image.asset(A.apple, fit: BoxFit.contain),
      ),
    );
  }

  Widget _deathOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _deathMsg ?? '',
                textAlign: TextAlign.center,
                style: AppTheme.marker(28, color: AppTheme.blood),
              ),
              const SizedBox(height: 8),
              Text(
                '+$_score Murilos',
                style: AppTheme.hand(22, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Text(
                      'De novo',
                      style: AppTheme.hand(18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Text(
                      'Voltar',
                      style: AppTheme.hand(18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int cols;
  final int rows;
  _GridPainter(this.cols, this.rows);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final cw = size.width / cols;
    final ch = size.height / rows;
    for (var x = 0; x <= cols; x++) {
      canvas.drawLine(Offset(x * cw, 0), Offset(x * cw, size.height), paint);
    }
    for (var y = 0; y <= rows; y++) {
      canvas.drawLine(Offset(0, y * ch), Offset(size.width, y * ch), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
