import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Inizializza i dati dei fusi orari
    tz_data.initializeTimeZones();

    // Impostiamo manualmente Roma per evitare dipendenze esterne
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    // 2. Configurazione Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notifica cliccata!");
      },
    );

    // 3. Permessi Android 13/14
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final bool? granted = await androidPlugin
          .requestNotificationsPermission();
      debugPrint('POST_NOTIFICATIONS granted: $granted');

      final bool? exact = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('Exact alarms permission: $exact');
    }

    // 4. Programma e mostra test
    await scheduleDailyNotifications();
    // await _showInstantTest();
    await _showImmediateTest(); // Aggiunto test immediato
  }

  static Future<void> _showImmediateTest() async {
    debugPrint("🔥 Chiamando _showImmediateTest()");
    await _notificationsPlugin.show(
      id: 999,
      title: "Test Immediato! ⚡",
      body: "Notifica mostrata subito dopo l'avvio.",
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spese_channel',
          'Spese Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    debugPrint("✅ _showImmediateTest() completata");
  }

  // static Future<void> _showInstantTest() async {
  //   await _notificationsPlugin.show(
  //     id: 888,
  //     title: "Sistema Pronto! 🚀",
  //     body: "Inizializzato con successo.",
  //     notificationDetails: const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'spese_channel_v3',
  //         'Promemoria Spese',
  //         importance: Importance.max,
  //         priority: Priority.high,
  //       ),
  //     ),
  //   );
  // }

  static Future<void> scheduleDailyNotifications() async {
    await _notificationsPlugin.cancelAll();

    // Notifiche giornaliere programmate
    // await _schedule(id: 199, title: "Promemoria!", body: "Segna le spese", hour: 16, minute: 22);
    await _schedule(id: 1, title: "Buongiorno! ☕", body: "Spese colazione?", hour: 9, minute: 0);
    await _schedule(id: 2, title: "Pausa pranzo? 🥪", body: "Segna le spese!", hour: 15, minute: 0);
    await _schedule(id: 3, title: "Fine giornata! 🌙", body: "Ultime spese?", hour: 21, minute: 30);
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // SOLUZIONE: Usa Timer di Dart invece di zonedSchedule per evitare problemi Android
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Se l'orario è già passato oggi, programma per domani
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Calcola quanti secondi mancano all'orario programmato
    final delaySeconds = scheduledDate.difference(now).inSeconds;

    debugPrint("⏰ Programmando notifica ID $id per ${scheduledDate.toString()} (tra $delaySeconds secondi)");

    // Usa Future.delayed per mostrare la notifica all'orario esatto
    Future.delayed(Duration(seconds: delaySeconds), () async {
      debugPrint("⏰ Notifica ID $id SCATTATA alle ${DateTime.now().toString()}");
      try {
        await _notificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'spese_channel_v3',
              'Promemoria Spese',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
            ),
          ),
        );
        debugPrint("✅ Notifica ID $id MOSTRATA con successo");
      } catch (e) {
        debugPrint("❌ Errore mostrando notifica ID $id: $e");
      }
    });
  }
}
