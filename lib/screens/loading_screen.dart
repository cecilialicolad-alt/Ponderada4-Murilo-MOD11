import 'package:flutter/material.dart';

import '../data/asset_paths.dart';
import '../services/ranking_service.dart';
import '../theme/app_theme.dart';
import 'main_game_screen.dart';

class LoadingScreen extends StatefulWidget {
  final RankingService rankingService;
  const LoadingScreen({super.key, required this.rankingService});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, a, _) => FadeTransition(
            opacity: a,
            child: MainGameScreen(rankingService: widget.rankingService),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spin,
              child: Image.asset(A.skinBase, width: 150, height: 150),
            ),
            const SizedBox(height: 28),
            Text('carregando...', style: AppTheme.hand(20)),
          ],
        ),
      ),
    );
  }
}
