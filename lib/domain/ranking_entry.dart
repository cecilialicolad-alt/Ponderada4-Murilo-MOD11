class RankingEntry {
  final String id;
  final String name;
  final int score;

  final bool hasPhoto;

  final bool isMurilo;

  const RankingEntry({
    required this.id,
    required this.name,
    required this.score,
    this.hasPhoto = false,
    this.isMurilo = false,
  });

  RankingEntry copyWith({
    String? name,
    int? score,
    bool? hasPhoto,
    bool? isMurilo,
  }) {
    return RankingEntry(
      id: id,
      name: name ?? this.name,
      score: score ?? this.score,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      isMurilo: isMurilo ?? this.isMurilo,
    );
  }
}

class SubmitScoreRequest {
  final String playerName;
  final int score;

  const SubmitScoreRequest({required this.playerName, required this.score});
}
