sealed class AppError implements Exception {
  final String message;
  const AppError(this.message);

  @override
  String toString() => message;
}

class RankingUnavailableError extends AppError {
  const RankingUnavailableError([
    super.message = 'Não foi possível carregar o ranking agora.',
  ]);
}

class InvalidScoreError extends AppError {
  const InvalidScoreError([super.message = 'Pontuação inválida.']);
}

class LocationUnavailableError extends AppError {
  const LocationUnavailableError([
    super.message = 'Não foi possível obter sua localização.',
  ]);
}
