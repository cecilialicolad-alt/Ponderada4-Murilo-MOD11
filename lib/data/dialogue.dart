import 'dart:math';

class Dialogue {
  Dialogue._();
  static final Random _rng = Random();

  static const List<String> falasCurtas = [
    'Ei',
    'Ou',
    '??',
    'Umm',
    'Oi',
    'Opa',
  ];

  static const List<String> falasInquietas = [
    'hum',
    'que fome',
    'repita',
    'novamente',
    'continue',
    'mais',
  ];

  static const List<String> falasFamintas = [
    'CLIQUE',
    'FOME',
    'MUITA FOME',
    'ESTOU FICANDO IMPACIENTE',
    'VOCÊ NÃO QUER ME DEIXAR BRAVO',
  ];

  static const List<String> derrotaLeve = [
    'ele não gostou disso',
    'não fez um bom trabalho',
    'menos nota de participação',
    'NÃO',
  ];

  static const List<String> derrotaMedia = [
    'ele REALMENTE não gostou disso',
    'ele não está feliz...',
    'CUIDADO',
    'você consegue fazer melhor?',
  ];

  static const List<String> derrotaPesada = [
    'ele está vindo...',
    'ele está PRÓXIMO',
    'ELE ESTÁ CHEGANDO',
    'corra.',
  ];

  static const List<String> lembretes = [
    'Murilo está esperando.',
    'você não vai me visitar?',
    'ele está de olho.',
    'ele está ficando impaciente.',
    'volte. agora.',
  ];

  static String _pick(List<String> l) => l[_rng.nextInt(l.length)];

  static String fala(int dreadStage) {
    if (dreadStage <= 4) return _pick(falasCurtas);
    if (dreadStage <= 7) return _pick(falasInquietas);
    return _pick(falasFamintas);
  }

  static String derrota(int dreadStage) {
    if (dreadStage <= 2) return _pick(derrotaLeve);
    if (dreadStage <= 5) return _pick(derrotaMedia);
    return _pick(derrotaPesada);
  }

  static String lembrete() => _pick(lembretes);
}
