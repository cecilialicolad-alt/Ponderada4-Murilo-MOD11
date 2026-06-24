import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/asset_paths.dart';
import '../data/dialogue.dart';
import '../presentation/widgets/corruption_effects.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class FlappyScreen extends StatefulWidget {
  const FlappyScreen({super.key});

  @override
  State<FlappyScreen> createState() => _FlappyScreenState();
}

class _Pipe {
  double x;
  final double gapCenter;
  bool passed = false;
  _Pipe(this.x, this.gapCenter);
}

class _FlappyScreenState extends State<FlappyScreen>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 2.4;
  static const double _jump = -0.85;
  static const double _birdX = 0.28;
  static const double _birdRadius = 0.055;
  static const double _pipeWidth = 0.16;
  static const double _gap = 0.42;
  static const double _spacing = 0.66;

  final _game = GameState.instance;
  final _rng = Random();

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  double _birdY = 0.5;
  double _vel = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _started = false;
  bool _dead = false;
  bool _wingUp = false;
  String? _deathMsg;
  int _lives = 3;

  @override
  void initState() {
    super.initState();
    _pipes.add(_Pipe(1.5, 0.5));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _randomGap() => 0.25 + _rng.nextDouble() * 0.5;

  double get _speed => 0.30 + (_score ~/ 20) * 0.01;

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _wingUp = (elapsed.inMilliseconds ~/ 160).isEven;
    if (_started && !_dead) {
      _update(dt.clamp(0.0, 0.05));
    } else {
      setState(() {});
    }
  }

  void _flap() {
    if (_dead) return;
    _started = true;
    _vel = _jump;
  }

  void _update(double dt) {
    _vel += _gravity * dt;
    _birdY += _vel * dt;

    for (final p in _pipes) {
      p.x -= _speed * dt;
      if (!p.passed && p.x + _pipeWidth < _birdX) {
        p.passed = true;
        _score += 20;
      }
    }
    _pipes.removeWhere((p) => p.x + _pipeWidth < -0.1);
    if (_pipes.isEmpty || _pipes.last.x < 1 - _spacing) {
      _pipes.add(_Pipe(1.0, _randomGap()));
    }

    if (_birdY < 0 || _birdY > 1 || _hitsPipe()) {
      _loseLife();
    }
    setState(() {});
  }

  bool _hitsPipe() {
    for (final p in _pipes) {
      final withinX =
          _birdX + _birdRadius > p.x && _birdX - _birdRadius < p.x + _pipeWidth;
      if (!withinX) continue;
      final gapTop = p.gapCenter - _gap / 2;
      final gapBottom = p.gapCenter + _gap / 2;
      if (_birdY - _birdRadius < gapTop || _birdY + _birdRadius > gapBottom) {
        return true;
      }
    }
    return false;
  }

  void _loseLife() {
    _lives--;
    if (_lives <= 0) {
      _die();
      return;
    }
    _birdY = 0.5;
    _vel = 0;
    _pipes.removeWhere((p) => p.x < _birdX + 0.5);
  }

  void _die() {
    if (_dead) return;
    _dead = true;
    _ticker.stop();
    _deathMsg = Dialogue.derrota(_game.dreadStage);
    _game.addMurilos(_score);
    _game.startCooldown(3);
    setState(() {});
  }

  void _restart() {
    setState(() {
      _birdY = 0.5;
      _vel = 0;
      _pipes
        ..clear()
        ..add(_Pipe(1.5, 0.5));
      _score = 0;
      _lives = 3;
      _started = false;
      _dead = false;
      _deathMsg = null;
      _last = Duration.zero;
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFE0EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFE0EF),
        elevation: 0,
        foregroundColor: AppTheme.ink,
        centerTitle: true,
        title: Text('VOO DO MURILO', style: AppTheme.marker(20)),
      ),
      body: CorruptionEffects(
        shake: 3,
        tint: 0.13,
        child: GestureDetector(
          onTap: _flap,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final birdSize = w * 0.22;
              final tilt = (_vel * 0.5).clamp(-0.5, 1.0);
              return Stack(
                children: [
                  for (final p in _pipes) ..._pipeWidgets(p, w, h),
                  Positioned(
                    left: _birdX * w - birdSize / 2,
                    top: _birdY * h - birdSize / 2,
                    child: Transform.rotate(
                      angle: tilt,
                      child: Image.asset(
                        _wingUp ? A.flappy1 : A.flappy2,
                        width: birdSize,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text('$_score', style: AppTheme.marker(48)),
                        Text(
                          '❤' * _lives,
                          style: AppTheme.marker(18, color: AppTheme.blood),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'toque no Murilo para voar • desvie dos canos',
                          textAlign: TextAlign.center,
                          style: AppTheme.hand(15, color: AppTheme.ink),
                        ),
                      ],
                    ),
                  ),
                  if (_dead) _deathOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _pipeWidgets(_Pipe p, double w, double h) {
    final left = p.x * w;
    final pw = _pipeWidth * w;
    final gapTop = (p.gapCenter - _gap / 2) * h;
    final gapBottom = (p.gapCenter + _gap / 2) * h;
    return [
      Positioned(left: left, top: 0, width: pw, height: gapTop, child: _pipe()),
      Positioned(
        left: left,
        top: gapBottom,
        width: pw,
        bottom: 0,
        child: _pipe(),
      ),
    ];
  }

  Widget _pipe() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF4E7A3A),
      border: Border.all(color: Colors.black87, width: 3),
      borderRadius: BorderRadius.circular(6),
    ),
  );

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
                    onPressed: _restart,
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
