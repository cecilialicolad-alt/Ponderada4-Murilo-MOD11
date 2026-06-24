import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/dialogue.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'murilo_dread';
  static const String _channelName = 'Murilo';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Avisos do Murilo',
      importance: Importance.max,
    );
    await _android?.createNotificationChannel(channel);
    await _android?.requestNotificationsPermission();
  }

  Future<void> showDread(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showAwayReminder() => showDread('Murilo', Dialogue.lembrete());
}
