import 'package:flutter/material.dart';

import '../data/asset_paths.dart';
import '../domain/errors.dart';
import '../domain/ranking_entry.dart';
import '../services/ranking_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class RankingScreen extends StatefulWidget {
  final RankingService service;

  final bool revealMurilo;

  const RankingScreen({
    super.key,
    required this.service,
    this.revealMurilo = false,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingEntry>> _future;
  late final TextEditingController _nameCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: GameState.instance.playerName);
    _future = _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<List<RankingEntry>> _load() async {
    var entries = await widget.service.topPlayers();
    if (widget.revealMurilo) entries = widget.service.revealMurilo(entries);
    final game = GameState.instance;
    if (!entries.any((e) => e.name == game.playerName)) {
      entries = [
        ...entries,
        RankingEntry(
          id: 'me',
          name: game.playerName,
          score: game.murilos,
          hasPhoto: true,
        ),
      ]..sort((a, b) => b.score.compareTo(a.score));
    }
    return entries;
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _submitMyScore() async {
    final game = GameState.instance;
    game.setPlayerName(_nameCtrl.text);
    setState(() => _submitting = true);
    try {
      await widget.service.registerScore(
        playerName: game.playerName,
        score: game.murilos,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pontuação enviada!')));
      _refresh();
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        title: Text('RANKING', style: AppTheme.marker(24)),
      ),
      body: Column(
        children: [
          Expanded(child: _body()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  textAlign: TextAlign.center,
                  maxLength: 20,
                  style: AppTheme.hand(18),
                  decoration: const InputDecoration(
                    labelText: 'Seu nome no ranking',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                    ),
                    onPressed: _submitting ? null : _submitMyScore,
                    child: Text(
                      _submitting ? 'Enviando...' : 'Salvar e enviar pontuação',
                      style: AppTheme.hand(20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return FutureBuilder<List<RankingEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.ink),
          );
        }
        if (snapshot.hasError) {
          final msg = snapshot.error is AppError
              ? (snapshot.error as AppError).message
              : 'Algo deu errado.';
          return _ErrorView(message: msg, onRetry: _refresh);
        }
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return Center(
            child: Text('Ninguém no ranking ainda.', style: AppTheme.hand(20)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _RankRow(position: i + 1, entry: entries[i]),
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  final int position;
  final RankingEntry entry;
  const _RankRow({required this.position, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isYou =
        !entry.isMurilo && entry.name == GameState.instance.playerName;
    final accent = entry.isMurilo
        ? AppTheme.blood
        : (isYou ? AppTheme.xpGreen : AppTheme.ink);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isYou ? const Color(0xFFF1F8E9) : Colors.white,
        border: Border.all(
          color: accent,
          width: (entry.isMurilo || isYou) ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text('$position', style: AppTheme.marker(22)),
          const SizedBox(width: 12),
          _avatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isYou ? '${entry.name} (você)' : entry.name,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.hand(
                20,
                color: entry.isMurilo ? AppTheme.blood : AppTheme.ink,
              ),
            ),
          ),
          Text('${entry.score}', style: AppTheme.marker(20)),
        ],
      ),
    );
  }

  Widget _avatar() {
    if (entry.isMurilo && entry.hasPhoto) {
      return const CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage(A.skinFinal),
      );
    }
    if (entry.isMurilo) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.black,
        child: Text('?', style: TextStyle(color: Colors.white)),
      );
    }
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Colors.black12,
      child: Icon(Icons.person, size: 20, color: Colors.black45),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.hand(20),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('Tentar de novo', style: AppTheme.hand(18)),
            ),
          ],
        ),
      ),
    );
  }
}
