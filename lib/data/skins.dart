import 'asset_paths.dart';

class Skin {
  final String name;
  final String asset;
  final int unlockLevel;
  const Skin(this.name, this.asset, this.unlockLevel);
}

class Skins {
  Skins._();

  static const List<Skin> all = [
    Skin('Murilo', A.skinBase, 1),
    Skin('Murilo Anjo', A.skinAnjo, 2),
    Skin('Murilo Pikachu', A.skinPikachu, 3),
    Skin('Murilo Shiny', A.skinPikachuShiny, 4),
    Skin('Murilo Anime', A.skinAnime, 5),
    Skin('Murilo Palhaço', A.skinPalhaco, 6),
    Skin('Murilo Golden', A.skinGolden, 7),
    Skin('Murilo Ash', A.skinAsh, 8),
    Skin('Murilo Demônio', A.skinDemonio, 8),
  ];

  static const Skin finalSkin = Skin('???', A.skinFinal, 9999);
}
