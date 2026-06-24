import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/asset_paths.dart';
import '../data/dialogue.dart';
import '../presentation/widgets/asset_icon_button.dart';
import '../presentation/widgets/corruption_effects.dart';
import '../presentation/widgets/falling_face.dart';
import '../presentation/widgets/floating_fala.dart';
import '../presentation/widgets/game_bottom_bar.dart';
import '../presentation/widgets/game_top_bar.dart';
import '../presentation/widgets/minigame_slots.dart';
import '../presentation/widgets/new_badge.dart';
import '../services/ranking_service.dart';
import '../services/share_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import 'flappy_screen.dart';
import 'game_over_screen.dart';
import 'map_screen.dart';
import 'ranking_screen.dart';
import 'skins_screen.dart';
import 'snake_screen.dart';
import 'whack_screen.dart';

class MainGameScreen extends StatefulWidget {
  final RankingService rankingService;
  const MainGameScreen({super.key, required this.rankingService});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen>
    with TickerProviderStateMixin {
  final _game = GameState.instance;
  final _rng = Random();
  final _shareService = const ShareService();

  static const double _faceAlignY = -0.2;

  late final AnimationController _wiggle;
  late final AnimationController _pop;
  late final AnimationController _reveal;
  late final AnimationController _fala;

  final List<FallingFaceData> _particles = [];
  int _particleId = 0;
  int _gainTick = 0;
  String _falaText = '';
  bool _started = false;

  int _lastDistanceBucket = -1;
  Timer? _urgentTimer;
  String? _urgentMsg;

  int _flashTick = 0;

  bool _finaleShown = false;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fala = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _started = _game.hasOnboarded;
    _reveal.value = _started ? 1.0 : 0.0;
    _game.addListener(_onGameChange);
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChange);
    _urgentTimer?.cancel();
    _wiggle.dispose();
    _pop.dispose();
    _reveal.dispose();
    _fala.dispose();
    super.dispose();
  }

  void _onGameChange() {
    if (_game.finalPhase && !_game.corruptionAcknowledged) {
      _triggerCorruption();
    }
    if (_game.isGameOver && !_finaleShown) {
      _finaleShown = true;
      _showFinale();
      return;
    }
    if (!_game.finalPhase) return;
    final bucket = (_game.muriloDistanceMeters / 100).floor();
    if (_lastDistanceBucket == -1) {
      _lastDistanceBucket = bucket;
      return;
    }
    if (bucket != _lastDistanceBucket) {
      final closer = bucket < _lastDistanceBucket;
      _lastDistanceBucket = bucket;
      if (closer) _showUrgency();
    }
  }

  void _showUrgency() {
    if (!mounted) return;
    final d = _game.muriloDistanceMeters.round();
    setState(
      () => _urgentMsg =
          'ELE ESTÁ A ${d}m\n${Dialogue.derrota(_game.dreadStage)}',
    );
    _urgentTimer?.cancel();
    _urgentTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _urgentMsg = null);
    });
  }

  void _showFinale() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GameOverScreen()));
  }

  void _triggerCorruption() {
    _game.acknowledgeCorruption();
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _flashSequence(3);
  }

  void _flashSequence(int n) {
    if (n <= 0 || !mounted) return;
    setState(() => _flashTick++);
    Future.delayed(
      const Duration(milliseconds: 280),
      () => _flashSequence(n - 1),
    );
  }

  void _onTapFace() {
    if (!_started) {
      _startGame();
      return;
    }
    _game.tapMurilo();
    _pop.forward(from: 0);
    _falaText = _game.currentFala;
    _fala.forward(from: 0);
    setState(() {
      _gainTick++;
      _particles.add(
        FallingFaceData(
          id: _particleId++,
          dx: (_rng.nextDouble() - 0.5) * 0.8,
          asset: _game.currentSkin.asset,
          rotation: (_rng.nextDouble() - 0.5) * 0.9,
          durationMs: 1100 + _rng.nextInt(500),
        ),
      );
    });
  }

  void _startGame() {
    _started = true;
    _game.markOnboarded();
    _reveal.forward();
    setState(() {});
  }

  void _devReset() {
    _game.reset();
    _reveal.value = 0.0;
    setState(() {
      _started = false;
      _particles.clear();
    });
    _placeholder('Progresso zerado (dev)');
  }

  Widget _devSkipButton() {
    return TextButton(
      onPressed: () => _game.devAdvance(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'DEV pular fase',
        style: AppTheme.hand(13, color: AppTheme.blood),
      ),
    );
  }

  void _placeholder(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  void _corruptError() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _flashSequence(1);
    _placeholder('Corrompido. Só resta... ele.');
  }

  void _openRanking() {
    if (_game.finalPhase) {
      _corruptError();
      return;
    }
    _game.markSeen('ranking');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RankingScreen(service: widget.rankingService),
      ),
    );
  }

  void _openMap() {
    if (!_game.isMinigameUnlocked(2)) {
      _placeholder('Mapa bloqueado — chegue mais longe');
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  void _openSkins() {
    if (_game.finalPhase) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      _flashSequence(1);
      _placeholder('A loja foi... corrompida.');
      return;
    }
    _game.markSkinsSeen();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SkinsScreen()));
  }

  void _openShareSheet() {
    if (_game.finalPhase) {
      _corruptError();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.paper,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline, color: AppTheme.ink),
              title: Text('Mandar convite', style: AppTheme.hand(20)),
              subtitle: Text(
                '"Murilo está esperando"',
                style: AppTheme.hand(15, color: Colors.black54),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareService.shareInvite();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.emoji_events_outlined,
                color: AppTheme.ink,
              ),
              title: Text('Compartilhar pontuação', style: AppTheme.hand(20)),
              subtitle: Text(
                '${_game.murilos} Murilos',
                style: AppTheme.hand(15, color: Colors.black54),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareService.shareScore(_game.murilos);
              },
            ),
          ],
        ),
      ),
    );
  }

  int _cdSecs(int id) {
    final left = _game.cooldownLeft(id);
    return left == Duration.zero ? 0 : (left.inMilliseconds / 1000).ceil();
  }

  List<MinigameSlot> _buildSlots() => [
    MinigameSlot(
      id: 1,
      label: 'Whack-a-Murilo',
      asset: A.iconWhack,
      unlocked: _game.isMinigameUnlocked(1),
      cooldownSeconds: _cdSecs(1),
      isNew: _game.hasBadge('minigame1'),
    ),
    MinigameSlot(
      id: 2,
      label: 'Cobra Murilo',
      asset: A.iconSnake,
      unlocked: _game.isMinigameUnlocked(2),
      cooldownSeconds: _cdSecs(2),
      isNew: _game.hasBadge('minigame2'),
    ),
    MinigameSlot(
      id: 3,
      label: 'Voo do Murilo',
      asset: A.iconFlappy,
      unlocked: _game.isMinigameUnlocked(3),
      cooldownSeconds: _cdSecs(3),
      isNew: _game.hasBadge('minigame3'),
    ),
  ];

  void _onTapSlot(MinigameSlot slot) {
    if (!slot.unlocked) {
      _placeholder('Bloqueado — junte mais Murilos');
      return;
    }
    if (_game.isOnCooldown(slot.id)) {
      _placeholder('Em cooldown: ${_cdSecs(slot.id)}s');
      return;
    }
    _game.markSeen('minigame${slot.id}');
    if (slot.id == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WhackScreen()));
      return;
    }
    if (slot.id == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SnakeScreen()));
      return;
    }
    if (slot.id == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FlappyScreen()));
      return;
    }
    _placeholder('${slot.label} — em breve 👀');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Stack(
          children: [
            CorruptionEffects(
              shake: 1.5,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _game,
                  _reveal,
                  _wiggle,
                  _pop,
                  _fala,
                ]),
                builder: (context, _) {
                  final reveal = Curves.easeOut.transform(_reveal.value);
                  final hudVisible = reveal > 0.99;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        if (_game.inFinalStretch) _finalStretchCounter(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _devSkipButton(),
                        ),
                        _fadeHud(
                          reveal,
                          hudVisible,
                          GameTopBar(
                            level: _game.level,
                            xpProgress: _game.xpProgress,
                            gainTick: _gainTick,
                            intoLevel: _game.pointsIntoLevel,
                            levelTarget: _game.pointsForThisLevel,
                            onLevelLongPress: _devReset,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _fadeHud(
                          reveal,
                          hudVisible,
                          MinigameSlots(
                            slots: _buildSlots(),
                            onTap: _onTapSlot,
                          ),
                        ),
                        Expanded(child: _centerArea(reveal)),
                        _fadeHud(
                          reveal,
                          hudVisible,
                          GameBottomBar(
                            mapUnlocked: _game.isMinigameUnlocked(2),
                            corrupted: _game.finalPhase,
                            onRanking: _openRanking,
                            onMap: _openMap,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_game.finalPhase)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppTheme.blood.withValues(alpha: 0.12),
                  ),
                ),
              ),
            if (_flashTick > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_flashTick),
                    tween: Tween(begin: 0.7, end: 0.0),
                    duration: const Duration(milliseconds: 240),
                    builder: (context, v, _) =>
                        Container(color: AppTheme.blood.withValues(alpha: v)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fadeHud(double reveal, bool visible, Widget child) {
    return Opacity(
      opacity: reveal,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }

  Widget _centerArea(double reveal) {
    final introScale = 1.0 + (1 - _reveal.value) * 0.5;
    final popScale = 1 + sin(pi * _pop.value) * 0.16;
    final faceScale = introScale * popScale;
    final wiggle = sin(_wiggle.value * 2 * pi) * 0.045;
    final glitch = _game.finalPhase && sin(_wiggle.value * 2 * pi * 9) > 0.9
        ? const Offset(7, -3)
        : Offset.zero;

    return Stack(
      fit: StackFit.expand,
      children: [
        ..._particles.map(
          (p) => FallingFace(
            key: ValueKey(p.id),
            data: p,
            faceY: _faceAlignY,
            onDone: () =>
                setState(() => _particles.removeWhere((e) => e.id == p.id)),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: Center(
                  child: (_fala.value > 0 && _falaText.isNotEmpty)
                      ? FloatingFala(text: _falaText, t: _fala.value)
                      : const SizedBox.shrink(),
                ),
              ),
              Transform.translate(
                offset: glitch,
                child: GestureDetector(
                  onTap: _onTapFace,
                  child: Transform.rotate(
                    angle: wiggle,
                    child: Transform.scale(
                      scale: faceScale,
                      child: Image.asset(
                        _game.currentSkin.asset,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Opacity(
                opacity: reveal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_game.murilos}', style: AppTheme.marker(56)),
                    Text(
                      'Murilos',
                      style: AppTheme.hand(16, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AssetIconButton(
                          asset: A.iconShare,
                          tooltip: 'Compartilhar',
                          height: 52,
                          enabled: !_game.finalPhase,
                          onTap: reveal > 0.99 ? _openShareSheet : null,
                        ),
                        const SizedBox(width: 20),
                        Badged(
                          show: _game.hasNewSkin,
                          child: AssetIconButton(
                            asset: A.iconSkins,
                            tooltip: 'Skins',
                            height: 52,
                            enabled: !_game.finalPhase,
                            onTap: reveal > 0.99 ? _openSkins : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (!_started)
          Align(
            alignment: const Alignment(0, 0.5),
            child: Opacity(
              opacity: (1 - reveal).clamp(0.0, 1.0),
              child: Text(
                'toque no Murilo',
                style: AppTheme.hand(22, color: Colors.black45),
              ),
            ),
          ),

        if (_urgentMsg != null)
          Align(alignment: const Alignment(0, -0.92), child: _urgencyBanner()),
      ],
    );
  }

  Widget _finalStretchCounter() {
    final d = _game.muriloDistanceMeters.round();
    return TweenAnimationBuilder<double>(
      key: ValueKey(d),
      tween: Tween(begin: 1.12, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.blood,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'ELE ESTÁ A $d m',
          textAlign: TextAlign.center,
          style: AppTheme.marker(22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _urgencyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.blood,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _urgentMsg ?? '',
        textAlign: TextAlign.center,
        style: AppTheme.marker(20, color: Colors.white),
      ),
    );
  }
}
