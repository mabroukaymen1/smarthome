import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static void initNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'flame_alert',
            channelName: 'Flame Alerts',
            channelDescription: 'Notifications for flame detection',
            defaultColor: Colors.red,
            importance: NotificationImportance.High,
            soundSource: 'resource://raw(default)',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error initializing awesome notifications: $e');
    }
  }

  static void sendFlameAlert() {
    try {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'flame_alert',
          title: '🔥 Flame Detected!',
          body:
              'Immediate action required. Flame detected in your environment.',
        ),
      );
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
