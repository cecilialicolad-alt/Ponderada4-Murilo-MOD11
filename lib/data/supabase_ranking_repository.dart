import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/errors.dart';
import '../domain/ranking_entry.dart';
import 'ranking_repository.dart';

class SupabaseRankingRepository implements RankingRepository {
  final SupabaseClient _client;

  SupabaseRankingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<void> submitScore(SubmitScoreRequest request) async {
    try {
      await _client.from('scores').insert({
        'player_name': request.playerName,
        'score': request.score,
        'is_murilo': false,
      });
    } catch (_) {
      throw const RankingUnavailableError(
        'Não foi possível enviar sua pontuação.',
      );
    }
  }

  @override
  Future<List<RankingEntry>> fetchTop(int limit) async {
    try {
      final rows = await _client
          .from('scores')
          .select('id, player_name, score, is_murilo')
          .order('score', ascending: false)
          .limit(limit);

      return rows.map<RankingEntry>((row) {
        final isMurilo = (row['is_murilo'] as bool?) ?? false;
        return RankingEntry(
          id: row['id'].toString(),
          name: row['player_name'] as String? ?? '???',
          score: (row['score'] as num?)?.toInt() ?? 0,
          hasPhoto: !isMurilo,
          isMurilo: isMurilo,
        );
      }).toList();
    } catch (_) {
      throw const RankingUnavailableError();
    }
  }
}
