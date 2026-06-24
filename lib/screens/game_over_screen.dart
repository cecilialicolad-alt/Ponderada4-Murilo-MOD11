import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/asset_paths.dart';
import '../state/game_state.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _jumpscare = false;
  Timer? _waitTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _knock();
    _waitTimer = Timer(const Duration(seconds: 15), _doJumpscare);
  }

  Future<void> _knock() async {
    for (var i = 0; i < 3; i++) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
    }
  }

  void _doJumpscare() {
    if (!mounted) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    setState(() => _jumpscare = true);
    _closeTimer = Timer(const Duration(milliseconds: 1500), () async {
      await GameState.instance.reset();
      await SystemNavigator.pop();
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_jumpscare) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: Image.asset(A.skinFinal, fit: BoxFit.cover),
        ),
      );
    }
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}
