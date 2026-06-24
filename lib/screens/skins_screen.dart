import 'package:flutter/material.dart';

import '../data/skins.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameState.instance;
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        foregroundColor: AppTheme.ink,
        centerTitle: true,
        title: Text('SKINS', style: AppTheme.marker(24)),
      ),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          return Column(
            children: [
              if (game.finalPhase)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Na fase final, o Murilo assume outra forma...',
                    textAlign: TextAlign.center,
                    style: AppTheme.hand(15, color: AppTheme.blood),
                  ),
                ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (var i = 0; i < Skins.all.length; i++)
                      _SkinCell(
                        skin: Skins.all[i],
                        unlocked: game.unlockedSkins.contains(i),
                        equipped: game.equippedSkin == i,
                        onTap: game.unlockedSkins.contains(i)
                            ? () => game.equipSkin(i)
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SkinCell extends StatelessWidget {
  final Skin skin;
  final bool unlocked;
  final bool equipped;
  final VoidCallback? onTap;

  const _SkinCell({
    required this.skin,
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: equipped ? AppTheme.blood : AppTheme.ink,
            width: equipped ? 4 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: unlocked
                  ? Image.asset(skin.asset, fit: BoxFit.contain)
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.lock, color: Colors.black38),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked
                  ? (equipped ? '✓ ${skin.name}' : skin.name)
                  : 'Nível ${skin.unlockLevel}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.hand(
                13,
                color: unlocked ? AppTheme.ink : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
