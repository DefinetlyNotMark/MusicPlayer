import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("Foreground Task Started");
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    print("Foreground Task Running...");
    
    sendPort?.send("Foreground Task Active");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print("Foreground Task Stopped");
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("Notification button $id pressed");
  }

  @override
  void onNotificationPressed() {
    print("Notification pressed");
  }
}
