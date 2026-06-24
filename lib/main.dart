import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'data/supabase_ranking_repository.dart';
import 'screens/loading_screen.dart';
import 'services/notification_service.dart';
import 'services/ranking_service.dart';
import 'state/game_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GameState.instance.load();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  final notificationService = NotificationService();
  await notificationService.init();

  final rankingService = RankingService(SupabaseRankingRepository());

  runApp(
    MuriloApp(
      rankingService: rankingService,
      notificationService: notificationService,
    ),
  );
}

class MuriloApp extends StatefulWidget {
  final RankingService rankingService;
  final NotificationService notificationService;

  const MuriloApp({
    super.key,
    required this.rankingService,
    required this.notificationService,
  });

  @override
  State<MuriloApp> createState() => _MuriloAppState();
}

class _MuriloAppState extends State<MuriloApp> with WidgetsBindingObserver {
  Timer? _decayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _decayTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => GameState.instance.applyDecay(),
    );
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && GameState.instance.hasOnboarded) {
      widget.notificationService.showAwayReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Murilo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: LoadingScreen(rankingService: widget.rankingService),
    );
  }
}
