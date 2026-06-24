import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dialogue.dart';
import '../data/skins.dart';

class GameState extends ChangeNotifier {
  GameState._();
  static final GameState instance = GameState._();

  int murilos = 0;
  int peak = 0;
  int totalTaps = 0;
  int equippedSkin = 0;
  Set<int> unlockedSkins = {0};
  Set<int> unlockedMinigames = {};

  Set<String> seenFeatures = {};

  int seenSkinCount = 1;

  bool corruptionAcknowledged = false;

  bool hasOnboarded = false;

  String currentFala = 'Ai';
  String playerName = '';

  final Map<int, int> _cooldownUntilMs = {};

  int corruptionTicks = 0;

  static const int minigame1Unlock = 15;
  static const int minigame2Unlock = 300;
  static const int minigame3Unlock = 2000;
  static const int corruptionThreshold = 3000;
  static const int cooldownSeconds = 60;

  int _cumulative(int l) => 50 * (l - 1) * l;

  int get level {
    var l = 1;
    while (_cumulative(l + 1) <= peak) {
      l++;
    }
    return l;
  }

  int get pointsForThisLevel => 100 * level;
  int get pointsIntoLevel => peak - _cumulative(level);
  double get xpProgress =>
      pointsForThisLevel == 0 ? 0 : pointsIntoLevel / pointsForThisLevel;

  bool get finalPhase => peak >= corruptionThreshold;

  int get dreadStage => level;

  Skin get currentSkin =>
      finalPhase ? Skins.finalSkin : Skins.all[equippedSkin];

  bool isMinigameUnlocked(int n) => unlockedMinigames.contains(n);

  double get muriloDistanceMeters =>
      finalPhase ? murilos.clamp(0, 3000).toDouble() : 3000;

  bool get isGameOver => finalPhase && murilos <= 0;

  static const int finalStretchMeters = 100;
  bool get inFinalStretch =>
      finalPhase && muriloDistanceMeters <= finalStretchMeters;

  bool hasBadge(String feature) =>
      _isFeatureUnlocked(feature) && !seenFeatures.contains(feature);

  bool _isFeatureUnlocked(String feature) {
    switch (feature) {
      case 'minigame1':
        return isMinigameUnlocked(1);
      case 'minigame2':
      case 'map':
        return isMinigameUnlocked(2);
      case 'minigame3':
        return isMinigameUnlocked(3);
      default:
        return true;
    }
  }

  Duration cooldownLeft(int id) {
    final until = _cooldownUntilMs[id];
    if (until == null) return Duration.zero;
    final left = until - DateTime.now().millisecondsSinceEpoch;
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  bool isOnCooldown(int id) => cooldownLeft(id) > Duration.zero;

  void startCooldown(int id) {
    _cooldownUntilMs[id] =
        DateTime.now().millisecondsSinceEpoch + cooldownSeconds * 1000;
    notifyListeners();
    save();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    murilos = p.getInt('murilos') ?? 0;
    peak = p.getInt('peak') ?? murilos;
    totalTaps = p.getInt('totalTaps') ?? 0;
    equippedSkin = p.getInt('equippedSkin') ?? 0;
    unlockedSkins = (p.getStringList('unlockedSkins') ?? ['0'])
        .map(int.parse)
        .toSet();
    unlockedMinigames = (p.getStringList('unlockedMinigames') ?? [])
        .map(int.parse)
        .toSet();
    seenFeatures = (p.getStringList('seenFeatures') ?? []).toSet();
    seenSkinCount = p.getInt('seenSkinCount') ?? 1;
    corruptionAcknowledged = p.getBool('corruptionAcknowledged') ?? false;
    hasOnboarded = p.getBool('hasOnboarded') ?? false;
    playerName = p.getString('playerName') ?? _randomPlayerName();
    _cooldownUntilMs.clear();
    for (final s in p.getStringList('cooldowns') ?? const <String>[]) {
      final parts = s.split(':');
      if (parts.length == 2) {
        _cooldownUntilMs[int.parse(parts[0])] = int.parse(parts[1]);
      }
    }
    _recompute();
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('murilos', murilos);
    await p.setInt('peak', peak);
    await p.setInt('totalTaps', totalTaps);
    await p.setInt('equippedSkin', equippedSkin);
    await p.setStringList(
      'unlockedSkins',
      unlockedSkins.map((e) => '$e').toList(),
    );
    await p.setStringList(
      'unlockedMinigames',
      unlockedMinigames.map((e) => '$e').toList(),
    );
    await p.setStringList('seenFeatures', seenFeatures.toList());
    await p.setInt('seenSkinCount', seenSkinCount);
    await p.setBool('corruptionAcknowledged', corruptionAcknowledged);
    await p.setBool('hasOnboarded', hasOnboarded);
    await p.setString('playerName', playerName);
    await p.setStringList(
      'cooldowns',
      _cooldownUntilMs.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }

  void tapMurilo() {
    totalTaps++;
    _earn(1);
    currentFala = Dialogue.fala(dreadStage);
    notifyListeners();
    save();
  }

  void addMurilos(int n) {
    _earn(n);
    notifyListeners();
    save();
  }

  void loseMurilos(int n) {
    murilos = max(0, murilos - n);
    notifyListeners();
    save();
  }

  void _earn(int n) {
    murilos += n;
    if (murilos > peak) peak = murilos;
    _recompute();
  }

  void applyDecay() {
    if (!finalPhase) return;
    corruptionTicks++;
    final amount = 6 + corruptionTicks ~/ 2;
    murilos = max(0, murilos - amount);
    notifyListeners();
    save();
  }

  void equipSkin(int index) {
    if (finalPhase) return;
    if (unlockedSkins.contains(index)) {
      equippedSkin = index;
      notifyListeners();
      save();
    }
  }

  void markOnboarded() {
    if (hasOnboarded) return;
    hasOnboarded = true;
    notifyListeners();
    save();
  }

  void markSeen(String feature) {
    if (seenFeatures.add(feature)) {
      notifyListeners();
      save();
    }
  }

  bool get hasNewSkin => !finalPhase && unlockedSkins.length > seenSkinCount;

  void markSkinsSeen() {
    if (seenSkinCount != unlockedSkins.length) {
      seenSkinCount = unlockedSkins.length;
      notifyListeners();
      save();
    }
  }

  void setPlayerName(String name) {
    final n = name.trim();
    if (n.isEmpty || n == playerName) return;
    playerName = n;
    notifyListeners();
    save();
  }

  void acknowledgeCorruption() {
    if (corruptionAcknowledged) return;
    corruptionAcknowledged = true;
    notifyListeners();
    save();
  }

  void devAdvance() {
    const thresholds = [
      minigame1Unlock,
      minigame2Unlock,
      minigame3Unlock,
      corruptionThreshold,
    ];
    for (final t in thresholds) {
      if (peak < t) {
        _setScore(t);
        return;
      }
    }
    _setScore(peak + 500);
  }

  void _setScore(int v) {
    murilos = v;
    if (v > peak) peak = v;
    _recompute();
    notifyListeners();
    save();
  }

  String _randomPlayerName() {
    final suffix = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'jogador_$suffix';
  }

  void _recompute() {
    if (peak >= minigame1Unlock) unlockedMinigames.add(1);
    if (peak >= minigame2Unlock) unlockedMinigames.add(2);
    if (peak >= minigame3Unlock) unlockedMinigames.add(3);
    for (var i = 0; i < Skins.all.length; i++) {
      if (level >= Skins.all[i].unlockLevel) unlockedSkins.add(i);
    }
  }

  Future<void> reset() async {
    murilos = 0;
    peak = 0;
    totalTaps = 0;
    equippedSkin = 0;
    unlockedSkins = {0};
    unlockedMinigames = {};
    seenFeatures = {};
    seenSkinCount = 1;
    corruptionAcknowledged = false;
    corruptionTicks = 0;
    hasOnboarded = false;
    currentFala = 'Ai';
    _cooldownUntilMs.clear();
    notifyListeners();
    await save();
  }
}
