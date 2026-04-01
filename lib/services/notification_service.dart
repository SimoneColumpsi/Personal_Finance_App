import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    
    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Chiedi il permesso (necessario per Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await scheduleDailyNotifications();
  }

  static Future<void> scheduleDailyNotifications() async {
    await _schedule(99, "Test Notifica! 🚀", "Se vedi questo, l'app è pronta!", 20, 22);
    
    await _schedule(1, "Buongiorno! ☕", "Hai fatto spese colazione o stanotte?", 9, 0);
    await _schedule(2, "Pausa caffè? 🥪", "Segna le spese di stamattina o del pranzo!", 15, 0);
    await _schedule(3, "Fine giornata! 🌙", "Com'è andato il pomeriggio? Segna le ultime spese.", 21, 30);
  }

  static Future<void> _schedule(
      int id, String title, String body, int hour, int minute) async {
    // FIX 2 e 3: zonedSchedule ora vuole le etichette per tutto (id:, title:, ecc.)
    // ed è stato rimosso uiLocalNotificationDateInterpretation
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spese_reminders', // Nuovo ID
          'Promemoria Spese', // Nuovo Nome
          channelDescription: 'Notifiche per ricordarti di segnare le spese',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    // AGGIUNGI QUESTA RIGA QUI SOTTO:
    print("✅ Notifica programmata: ID $id alle ore $hour:$minute");
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}