import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:musicplayer/services/foreground.dart';
import 'package:workmanager/workmanager.dart';
import '../models/music_model.dart';
import 'package:musicplayer/services/audioc_manager.dart';
import 'dart:math';
import '../services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock/wakelock.dart';

class CurrentSongService {
  static ValueNotifier<Music?> currentSongNotifier =
      ValueNotifier<Music?>(null);
  static int _currentIndex = 0;
  static bool isPlaying = false;
  static bool isRandomMode = false;
  static ValueNotifier<Duration> positionNotifier =
      ValueNotifier(Duration.zero);
  static ValueNotifier<Duration> durationNotifier =
      ValueNotifier(Duration.zero);
  static final AudioManager _audioManager = AudioManager();
  static List<Music> _musicList = [];
  static List<Music> _playlistMusicList = [];
  static final Random _random = Random();
  static bool isPlaylistScreenActive = false;
  static bool _isChangingSong = false;

  static void init() {
    _audioManager.audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        nextSong();
      } else if (state == PlayerState.playing) {
        isPlaying = true;
        _startForegroundService();
      } else {
        isPlaying = false;
        _stopForegroundService();
      }
      currentSongNotifier.value = currentSongNotifier.value;
    });

    _audioManager.audioPlayer.onPositionChanged.listen((pos) {
      positionNotifier.value = pos;
      _updateNotificationProgress();
    });

    _audioManager.audioPlayer.onDurationChanged.listen((dur) {
      if (dur.inSeconds > 0) {
        durationNotifier.value = dur;
        _updateNotificationProgress();
      }
    });
  }

  static void setMusicList(List<Music> list, {bool isPlaylist = false}) {
    if (isPlaylist) {
      _playlistMusicList = List.from(list);
    } else {
      _musicList = List.from(list);
    }
  }

  static void setPlaylistScreenActive(bool isActive) {
    isPlaylistScreenActive = isActive;
  }

  static List<Music> getActiveMusicList() {
    return isPlaylistScreenActive ? _musicList : _musicList;
  }

  static void setCurrentSong(Music song, int index) {
    _currentIndex = index;
    if (_musicList.isEmpty) {
      _musicList.add(song);
    }

    currentSongNotifier.value = song;
    isPlaying = true;
    debugPrint("▶️ Playing song: ${song.title} at index $index");
    _audioManager.play(song.url);

    enableWakeLock();

    NotificationService.showMusicNotification(song.title, song.album,
        isPlaying: isPlaying);
    currentSongNotifier.notifyListeners();
  }

  static List<Music> getMusicList() {
    return _musicList;
  }

  static int getCurrentIndex() {
    return _currentIndex;
  }

  static Future<void> seekTo(Duration position) async {
    await _audioManager.audioPlayer.seek(position);
  }

  static void togglePlayPause() async {
    if (isPlaying) {
      await _audioManager.pause();
      NotificationService.cancelNotification();
      _stopForegroundService();
    } else {
      await _audioManager.play(currentSongNotifier.value?.url ?? "");
      NotificationService.showMusicNotification(
        currentSongNotifier.value?.title ?? "Unknown",
        currentSongNotifier.value?.album ?? "Unknown Album",
      );
      _startForegroundService();
    }

    isPlaying = !isPlaying;
    debugPrint("Play/Pause toggled: $isPlaying");
    currentSongNotifier.notifyListeners();
  }

  static void nextSong() async {
    if (_isChangingSong || _musicList.isEmpty) {
      debugPrint("Next song is already in progress or no songs in the list.");
      return;
    }

    _isChangingSong = true;

    await Future.delayed(Duration(milliseconds: 100));

    int oldIndex = _currentIndex;

    if (isRandomMode) {
      int newIndex;
      do {
        newIndex = _random.nextInt(_musicList.length);
      } while (newIndex == _currentIndex);
      _currentIndex = newIndex;
    } else {
      _currentIndex = (_currentIndex + 1) % _musicList.length;
    }

    debugPrint("Next song: Old Index: $oldIndex, New Index: $_currentIndex");

    if (_currentIndex >= 0 && _currentIndex < _musicList.length) {
      setCurrentSong(_musicList[_currentIndex], _currentIndex);
    } else {
      debugPrint("Invalid index detected in nextSong()");
    }

    _isChangingSong = false;
  }

  static void previousSong() {
    if (_musicList.isEmpty) {
      debugPrint("No songs in the list.");
      return;
    }

    int oldIndex = _currentIndex;

    if (isRandomMode) {
      int newIndex;
      do {
        newIndex = _random.nextInt(_musicList.length);
      } while (newIndex == _currentIndex);
      _currentIndex = newIndex;
    } else {
      _currentIndex =
          (_currentIndex - 1 + _musicList.length) % _musicList.length;
    }

    debugPrint(
        "Previous song: Old Index: $oldIndex, New Index: $_currentIndex");

    if (_currentIndex >= 0 && _currentIndex < _musicList.length) {
      setCurrentSong(_musicList[_currentIndex], _currentIndex);
    } else {
      debugPrint("Invalid index detected in previousSong()");
    }
  }

  static void stopPlayback() async {
    await _audioManager.stop();
    isPlaying = false;
    currentSongNotifier.value = null;
    NotificationService.cancelNotification();
    _stopForegroundService();
    disableWakeLock(); 
      await Workmanager().cancelAll();
    currentSongNotifier.notifyListeners();
  }

  static Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

static Future<void> _startForegroundService() async {
  if (!await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.startService(
      notificationTitle: "Music Player",
      notificationText: "Playing: ${currentSongNotifier.value?.title ?? 'Unknown'}",
      callback: _foregroundTaskCallback,
    );
  }
}

static void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}




static void enableWakeLock() {
  Wakelock.enable();
}

static void disableWakeLock() {
  Wakelock.disable();
}

  static void _updateNotificationProgress() {
    NotificationService.showMusicNotification(
      currentSongNotifier.value?.title ?? "Unknown",
      currentSongNotifier.value?.album ?? "Unknown Album",
      isPlaying: isPlaying,
      progress: positionNotifier.value.inSeconds,
      max: durationNotifier.value.inSeconds,
    );
  }

static void backgroundTask() async {
    
    if (isPlaying) {
      if (!await FlutterForegroundTask.isRunningService) {
        await _startForegroundService();
      }

      // Update notification with the current song details
      NotificationService.showMusicNotification(
        currentSongNotifier.value?.title ?? "Unknown",
        currentSongNotifier.value?.album ?? "Unknown Album",
        isPlaying: isPlaying,
        progress: positionNotifier.value.inSeconds,
        max: durationNotifier.value.inSeconds,
      );
    } else {
      // Stop foreground service if music is paused or stopped
      await _stopForegroundService();
    }
  }


  static bool get currentPlayState => isPlaying;
}
