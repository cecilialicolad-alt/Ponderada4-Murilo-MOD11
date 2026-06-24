import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService();

  static const String _link =
      'https://cecilialicolad-alt.github.io/MuriloTeEspera/';

  Future<void> shareInvite() => _share(
    'Murilo está esperando. 👀\n\n'
    'Você não vai deixá-lo esperando, vai?\n\n$_link',
  );

  Future<void> shareScore(int murilos) =>
      _share('Tenho $murilos Murilos. 😏\nVocê consegue mais?\n\n$_link');

  Future<void> shareReveal(int murilos) => _share(
    'Murilo não estava esperando por nada bom...\n'
    'Sobrevivi com $murilos Murilos antes de ele chegar. 💀\n\n$_link',
  );

  Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
