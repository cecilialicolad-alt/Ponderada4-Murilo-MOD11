import 'package:flutter_test/flutter_test.dart';

import 'package:murilo_game/data/fake_ranking_repository.dart';
import 'package:murilo_game/services/ranking_service.dart';

void main() {
  test('topPlayers vem ordenado por score e com o Murilo no topo', () async {
    final service = RankingService(FakeRankingRepository());

    final top = await service.topPlayers();

    expect(top, isNotEmpty);
    for (var i = 0; i < top.length - 1; i++) {
      expect(top[i].score, greaterThanOrEqualTo(top[i + 1].score));
    }
    expect(top.first.isMurilo, isTrue);
  });

  test(
    'revealMurilo transforma o primeiro colocado críptico no Murilo',
    () async {
      final service = RankingService(FakeRankingRepository());

      final revealed = service.revealMurilo(await service.topPlayers());
      final murilo = revealed.firstWhere((e) => e.isMurilo);

      expect(murilo.name, 'MURILO');
      expect(murilo.hasPhoto, isTrue);
    },
  );
}
