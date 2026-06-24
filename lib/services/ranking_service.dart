import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

class RankingService {
  final RankingRepository _repository;

  const RankingService(this._repository);

  static const int podiumSize = 10;

  Future<List<RankingEntry>> topPlayers() => _repository.fetchTop(podiumSize);

  Future<void> registerScore({required String playerName, required int score}) {
    final safeScore = score < 0 ? 0 : score;
    return _repository.submitScore(
      SubmitScoreRequest(playerName: playerName, score: safeScore),
    );
  }

  List<RankingEntry> revealMurilo(List<RankingEntry> entries) {
    return entries
        .map(
          (entry) => entry.isMurilo
              ? entry.copyWith(name: 'MURILO', hasPhoto: true)
              : entry,
        )
        .toList();
  }
}
