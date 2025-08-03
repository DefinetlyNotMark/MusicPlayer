import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isMusicPlaying = false; 
  static bool _isNotificationDismissed = false; 

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("Notification tapped but will not dismiss.");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }
  static Future<void> showMusicNotification(
      String title, String artist,
      {bool isPlaying = true, int progress = 0, int max = 100}) async {
    debugPrint("📢 Showing/updating notification...");

    _isMusicPlaying = isPlaying;
    _isNotificationDismissed = false;

    const int notificationId = 1;

    final MediaStyleInformation mediaStyle = MediaStyleInformation(
      htmlFormatContent: true,
      htmlFormatTitle: true,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'music_channel',
      'Music Notifications',
      importance: Importance.low,
      priority: Priority.high,
      showWhen: true,
      playSound: false,
      ongoing: true, 
      autoCancel: false,
      onlyAlertOnce: true,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: mediaStyle,
      progress: progress,  
      maxProgress: max, 
      showProgress: true,
      indeterminate: false,
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      title,
      artist,
      notificationDetails,
      payload: "music_notification",
    );
  }

  static Future<void> onNotificationDismissed() async {
    if (_isMusicPlaying) {
      debugPrint("⏳ Notification dismissed. Waiting before restoring...");
      _isNotificationDismissed = true;

      await Future.delayed(Duration(seconds: 3));
      if (_isMusicPlaying && _isNotificationDismissed) {
        debugPrint("🔄 Re-showing notification (without pop-up)...");

        final AndroidNotificationDetails silentNotificationDetails =
            AndroidNotificationDetails(
          'music_channel',
          'Music Notifications',
          importance: Importance.low,
          priority: Priority.low,
          showWhen: false,
          playSound: false,
          ongoing: true,
          autoCancel: false,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

        final NotificationDetails notificationDetails =
            NotificationDetails(android: silentNotificationDetails);

        await _notificationsPlugin.show(
          1, 
          "Now Playing",
          "Unknown Artist",
          notificationDetails,
          payload: "music_notification",
        );

        debugPrint("✅ Notification restored (only in tray)!");
      }
    }
  }

  static Future<void> cancelNotification() async {
    debugPrint("🛑 Cancelling notification...");
    _isMusicPlaying = false;
    await _notificationsPlugin.cancel(1);
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint("Notification tapped but will not be dismissed.");
}
