import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
class AudioManager {
  static final AudioManager _singleton = AudioManager._internal();
  factory AudioManager() => _singleton;
  AudioPlayer audioPlayer = AudioPlayer();

  AudioManager._internal();

  // Add method to check if music is playing
  bool isPlaying() {
    return audioPlayer.state == PlayerState.playing;
  }

  // Play a new song
 Future<void> play(String filePath) async {
  if (!File(filePath).existsSync()) {
    print("Error: File not found at $filePath");
    return;
  }

  await audioPlayer.setSource(DeviceFileSource(filePath));
  await audioPlayer.resume();
}

  // Pause current song
  Future<void> pause() async {
    await audioPlayer.pause();
  }

  // Stop and release audio player
  Future<void> stop() async {
    await audioPlayer.stop();
    await audioPlayer.release();
  }

  
}
