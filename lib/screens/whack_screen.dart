import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/asset_paths.dart';
import '../data/dialogue.dart';
import '../presentation/widgets/corruption_effects.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class WhackScreen extends StatefulWidget {
  const WhackScreen({super.key});

  @override
  State<WhackScreen> createState() => _WhackScreenState();
}

class _Hole {
  String? type;
  int spawnId = 0;
}

class _WhackScreenState extends State<WhackScreen>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 9;
  static const int _roundSeconds = 30;
  static const int _pointsPerHit = 10;

  final _game = GameState.instance;
  final _rng = Random();
  final List<_Hole> _holes = List.generate(_gridSize, (_) => _Hole());

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  Timer? _spawnTimer;
  Timer? _clockTimer;
  int _score = 0;
  int _timeLeft = _roundSeconds;
  int _spawnCounter = 0;
  String? _dreadMsg;
  bool _finished = false;
  int _lives = 1;

  @override
  void initState() {
    super.initState();
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _spawn(),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _spawn() {
    final empty = <int>[
      for (var i = 0; i < _holes.length; i++)
        if (_holes[i].type == null) i,
    ];
    if (empty.isEmpty) return;
    final i = empty[_rng.nextInt(empty.length)];
    final isCapacete = _rng.nextDouble() < 0.25;
    final id = ++_spawnCounter;
    setState(() {
      _holes[i].type = isCapacete ? 'capacete' : 'murilo';
      _holes[i].spawnId = id;
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (_holes[i].spawnId == id) setState(() => _holes[i].type = null);
    });
  }

  void _tapHole(int i) {
    final hole = _holes[i];
    if (hole.type == null || _finished) return;

    if (hole.type == 'murilo') {
      setState(() {
        _score += _pointsPerHit;
        hole.type = null;
        hole.spawnId = ++_spawnCounter;
      });
    } else {
      setState(() {
        _lives--;
        hole.type = null;
        hole.spawnId = ++_spawnCounter;
        _dreadMsg = Dialogue.derrota(_game.dreadStage);
      });
      _shake.forward(from: 0);
      if (_lives <= 0) {
        Future.delayed(const Duration(milliseconds: 700), _endRound);
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _dreadMsg = null);
        });
      }
    }
  }

  void _tick() {
    if (_finished) return;
    setState(() => _timeLeft--);
    if (_timeLeft <= 0) _endRound();
  }

  void _endRound() {
    if (_finished) return;
    _finished = true;
    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _game.addMurilos(_score);
    _game.startCooldown(1);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text('Acabou!', style: AppTheme.marker(26)),
        content: Text('Você ganhou $_score Murilos.', style: AppTheme.hand(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('Voltar', style: AppTheme.hand(20)),
          ),
        ],
      ),
    );
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
        title: Text('WHACK-A-MURILO', style: AppTheme.marker(20)),
      ),
      body: CorruptionEffects(
        shake: 3,
        tint: 0.13,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final dx = sin(_shake.value * pi * 8) * 12 * (1 - _shake.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Column(
            children: [
              _statusBar(),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        children: [
                          for (var i = 0; i < _holes.length; i++) _holeCell(i),
                        ],
                      ),
                    ),
                    if (_dreadMsg != null)
                      Center(
                        child: Text(
                          _dreadMsg!,
                          textAlign: TextAlign.center,
                          style: AppTheme.marker(30, color: AppTheme.blood),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Murilos: $_score', style: AppTheme.marker(22)),
          Text('❤ $_lives', style: AppTheme.marker(22, color: AppTheme.blood)),
          Text('⏱ $_timeLeft', style: AppTheme.marker(22)),
        ],
      ),
    );
  }

  Widget _holeCell(int i) {
    final hole = _holes[i];
    return GestureDetector(
      onTap: () => _tapHole(i),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5B3A21),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 3),
              ),
            ),
          ),
          AnimatedScale(
            scale: hole.type == null ? 0.0 : 1.18,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutBack,
            child: hole.type == null
                ? const SizedBox.shrink()
                : Image.asset(
                    hole.type == 'capacete'
                        ? A.capacete
                        : _game.currentSkin.asset,
                    fit: BoxFit.contain,
                  ),
          ),
        ],
      ),
    );
  }
}
