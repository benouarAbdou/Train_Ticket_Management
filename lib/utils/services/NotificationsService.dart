import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Schedules a notification 30 minutes before the train departure
  Future<void> scheduleTicketNotification({
    required String trainId,
    required String departureCity,
    required String arrivalCity,
    required String departureTime, // Format: "HH:mm"
    required String departureDate, // Format: "yyyy-MM-dd"
  }) async {
    try {
      // Parse departure date and time in the local time zone
      final departureDateTime = DateTime.parse('$departureDate $departureTime');

      // Convert to TZDateTime in the local time zone
      final tz.TZDateTime scheduledDepartureDateTime = tz.TZDateTime.from(
        departureDateTime,
        tz.local,
      );

      // Calculate notification time (30 minutes before departure)
      final tz.TZDateTime notificationTime = scheduledDepartureDateTime
          .subtract(Duration(minutes: 30));

      // Skip if the notification time is in the past
      if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      // Notification details
      const androidDetails = AndroidNotificationDetails(
        'ticket_channel', // Channel ID
        'Ticket Reminders', // Channel Name
        channelDescription: 'Reminders for your train tickets',
        importance: Importance.max,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        trainId.hashCode, // Unique ID based on trainId
        'Train Departure Reminder',
        'Your train from $departureCity to $arrivalCity departs in 30 minutes at $departureTime',
        notificationTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

    } catch (e) {
    }
  }

  /// Cancels a scheduled notification
  Future<void> cancelNotification(String trainId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(trainId.hashCode);
    } catch (e) {
    }
  }

  /// Cancels all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
    }
  }
}
