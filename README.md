# Murilo — Ponderada 4

Essa documentaçõ foi feita com o auxílio de AI.
Abaixo está o link do vídeo de demonstração:

[Vídeo de Demonstração](https://drive.google.com/file/d/1jt5uy90MEgqfYMdG4UtRNWw5wL0I_csj/view?usp=sharing)

Como extra utilizei 'parte' dos princípios de Clean Code para realizar a ponderada, não utilizando muito de Clean Architechture. No vídeo resumi esse tópico a apenas Clean Code, mas foi uma confusão do momento.

### Abaixo contexto do app e explicação técnica + instruções de uso:

Jogo mobile, em **Flutter**, que começa como um *clicker* fofo e vai se
**corrompendo** até virar um jogo de suspense: o personagem "Murilo" fica com
fome, passa a drenar seus pontos e te persegue no mapa, via GPS, até o desfecho.

## Proposta

**Problema.** Jogos *clicker* prendem o jogador com recompensa infinita e, no
fim, são vazios. A proposta explora isso de forma lúdica.

**Solução.** Um jogo que **subverte a própria mecânica**: você clica para
acumular "Murilos", desbloqueia três minigames (Cobra, Voo e Whack), sobe de
nível e ganha skins. Ao ultrapassar 3000 pontos, o jogo **corrompe** — os pontos
começam a cair, o mapa mostra o Murilo se aproximando e o clima vira terror. É
uma crítica à mecânica de vício e o pano de fundo que integra os recursos mobile.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| App mobile | Flutter |
| Backend + Banco | Supabase (PostgreSQL, BaaS) |
| API externa | OpenStreetMap (tiles via `flutter_map`) |
| Hardware | GPS (`geolocator`) |
| Notificações | `flutter_local_notifications` |
| Compartilhamento | `share_plus` (share nativo) |
| Persistência local | `shared_preferences` |

## Requisitos mínimos atendidos

| # | Requisito | Como é atendido |
|---|-----------|-----------------|
| 1 | Implementação mobile | App nativo em Flutter (Android), não é web app |
| 2 | Múltiplas telas | Loading, Hub, Cobra, Voo, Whack, Ranking, Mapa, Skins e Game Over — com navegação entre elas |
| 3 | Backend funcional | Supabase: o app lê o ranking e envia a pontuação |
| 4 | Banco de dados | Tabela `scores` no Postgres do Supabase (ranking persistido); progresso local em `shared_preferences` |
| 5 | API externa | Tiles do OpenStreetMap no mapa — mostra a perseguição do Murilo |
| 6 | Notificações | Notificação local: ao sair do app, o Murilo chama o jogador de volta |
| 7 | Compartilhamento | Folha de share nativa para convite e pontuação |
| 8 | Hardware | GPS para obter a localização real e posicionar o mapa |

Extras do checklist: tratamento de **carregamento/erro/sucesso** nas telas de
Ranking e Mapa (com retry), interface coerente com a proposta e teste de unidade.

## Arquitetura

Organização em camadas (Clean Code), com a dependência sempre apontando para
baixo e o domínio sem conhecer infraestrutura:

```
lib/
  domain/         # entidades, DTOs e erros nomeados (sem Flutter/Supabase)
  data/           # RankingRepository (interface) + impl Supabase e Fake
  services/       # regras de negócio (ranking, localização, share, notificações)
  state/          # GameState — estado e economia do jogo (ChangeNotifier)
  presentation/   # widgets reutilizáveis
  screens/        # as telas
  config/ theme/  # configuração e tema
  main.dart       # composição (injeção de dependência)
```

O repositório de ranking é uma **interface** com duas implementações (Supabase e
um *fake* em memória), injetadas no `main.dart`. Isso permite testar as regras de
negócio sem banco nem rede — ver `test/ranking_service_test.dart`.

## Como executar

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(canal stable) e um dispositivo Android (com depuração USB) ou emulador.

```bash
flutter pub get
flutter run
```

O acesso ao Supabase já vem configurado em `lib/config/app_config.dart` (a chave
é *publishable* — pública por design; os dados são protegidos por RLS no banco).

Rodar os testes:

```bash
flutter test
```
