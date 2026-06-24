import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'new_badge.dart';

class MinigameSlot {
  final int id;
  final String label;
  final String asset;
  final bool unlocked;
  final int cooldownSeconds;
  final bool isNew;

  const MinigameSlot({
    required this.id,
    required this.label,
    required this.asset,
    required this.unlocked,
    this.cooldownSeconds = 0,
    this.isNew = false,
  });
}

class MinigameSlots extends StatelessWidget {
  final List<MinigameSlot> slots;
  final void Function(MinigameSlot slot) onTap;

  const MinigameSlots({super.key, required this.slots, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: slots.map(_buildSlot).toList(),
    );
  }

  Widget _buildSlot(MinigameSlot slot) {
    return Badged(
      show: slot.isNew,
      child: GestureDetector(
        onTap: () => onTap(slot),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              slot.unlocked
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(slot.asset, fit: BoxFit.contain),
                    )
                  : const Icon(Icons.lock, size: 30, color: Colors.black38),
              if (slot.cooldownSeconds > 0)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Text(
                    '${slot.cooldownSeconds}s',
                    style: AppTheme.marker(22, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
