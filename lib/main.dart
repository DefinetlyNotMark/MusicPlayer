import 'package:flutter/material.dart';
import 'views/music_selection_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musicplayer/services/current_song_service.dart'; // Ensure this import
import 'package:musicplayer/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestAudioPermission();
  await _createNotificationChannel();
  await _requestNotificationPermission();
  await _requestBatteryOptimization();
  await _requestStoragePermission();
  await _requestMediaPermission();
  await NotificationService.init();
  CurrentSongService.init();

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'music_player_task',
    'music_playback_task',
    frequency: Duration(minutes: 8),
    inputData: <String, dynamic>{'key': 'value'},
  );

  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        },
        child: const MusicSelectionScreen(),
      ),
    );
  }
}

void backgroundTaskCallback() {
  CurrentSongService.backgroundTask();
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    if (task == 'music_playback_task') {
      backgroundTaskCallback();
    }
    return Future.value(true);
  });
}

Future<void> _requestStoragePermission() async {
  final status = await Permission.storage.request();

  if (status.isGranted) {
    debugPrint("✅ Storage permission granted!");
  } else if (status.isDenied) {
    debugPrint("❌ Storage permission denied.");
  } else if (status.isPermanentlyDenied) {
    debugPrint(
        "⚠️ Storage permission permanently denied. Redirecting to settings.");
    await openAppSettings();
  }
}

Future<void> _requestMediaPermission() async {
  final status = await Permission.mediaLibrary.request();

  if (status.isGranted) {
    debugPrint("✅ Media permission granted!");
  } else {
    debugPrint("❌ Media permission denied.");
  }
}

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isGranted) {
    debugPrint("✅ Notification permission already granted!");
  } else if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint("✅ Notification permission granted!");
    } else {
      debugPrint("❌ Notification permission denied.");
    }
  }
}

Future<void> _requestAudioPermission() async {
  final status = await Permission.audio.request();

  if (status.isDenied) {
    debugPrint("❌ Audio permission denied. Requesting again...");
  } else if (status.isPermanentlyDenied) {
    debugPrint(
        "⚠️ Audio permission permanently denied. Redirecting to settings.");
    await openAppSettings();
  } else if (status.isGranted) {
    debugPrint("✅ Audio permission granted!");
  }
}

Future<void> _requestBatteryOptimization() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final manufacturer = androidInfo.manufacturer.toLowerCase();

  if (manufacturer.contains("xiaomi") ||
      manufacturer.contains("oppo") ||
      manufacturer.contains("vivo") ||
      manufacturer.contains("realme")) {
    debugPrint(
        "⚠️ Detected $manufacturer device. Requesting battery optimization disable.");
    _openBatterySettings();
  }
}

void _openBatterySettings() async {
  final intent = AndroidIntent(
    action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}

Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'music_channel',
    'Music Notifications',
    description: 'Persistent music player notifications',
    importance: Importance.max,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
