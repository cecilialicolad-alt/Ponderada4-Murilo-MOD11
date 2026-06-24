import '../domain/ranking_entry.dart';
import 'ranking_repository.dart';

class FakeRankingRepository implements RankingRepository {
  final List<RankingEntry> _entries = [
    const RankingEntry(
      id: 'murilo',
      name: '∎∎∎∎∎',
      score: 999999,
      hasPhoto: false,
      isMurilo: true,
    ),
    const RankingEntry(id: 'p1', name: 'usuario_4f2a', score: 2450),
    const RankingEntry(id: 'p2', name: 'guest_91c7', score: 1980),
    const RankingEntry(id: 'p3', name: 'anon_2d8e', score: 1610),
    const RankingEntry(id: 'p4', name: 'player_77b1', score: 1240),
    const RankingEntry(id: 'p5', name: 'usuario_0a3f', score: 920),
    const RankingEntry(id: 'p6', name: 'guest_5e9d', score: 640),
    const RankingEntry(id: 'p7', name: 'anon_8c12', score: 410),
    const RankingEntry(id: 'p8', name: 'player_3b6a', score: 230),
    const RankingEntry(id: 'p9', name: 'usuario_e7f0', score: 110),
  ];

  @override
  Future<void> submitScore(SubmitScoreRequest request) async {
    _entries.removeWhere((e) => e.id == 'you');
    _entries.add(
      RankingEntry(
        id: 'you',
        name: request.playerName,
        score: request.score,
        hasPhoto: true,
      ),
    );
  }

  @override
  Future<List<RankingEntry>> fetchTop(int limit) async {
    final sorted = [..._entries]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).toList();
  }
}
