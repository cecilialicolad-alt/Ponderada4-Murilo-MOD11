import '../domain/ranking_entry.dart';

abstract interface class RankingRepository {
  Future<void> submitScore(SubmitScoreRequest request);

  Future<List<RankingEntry>> fetchTop(int limit);
}
