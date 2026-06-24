import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import 'asset_icon_button.dart';

class GameBottomBar extends StatelessWidget {
  final bool mapUnlocked;
  final bool corrupted;
  final VoidCallback onRanking;
  final VoidCallback onMap;

  const GameBottomBar({
    super.key,
    required this.mapUnlocked,
    this.corrupted = false,
    required this.onRanking,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AssetIconButton(
            asset: A.iconRank,
            tooltip: 'Ranking',
            onTap: onRanking,
            enabled: !corrupted,
            height: 50,
          ),
          AssetIconButton(
            asset: A.iconMap,
            tooltip: 'Mapa',
            onTap: onMap,
            enabled: mapUnlocked,
            tremble: corrupted,
            height: 50,
          ),
        ],
      ),
    );
  }
}
