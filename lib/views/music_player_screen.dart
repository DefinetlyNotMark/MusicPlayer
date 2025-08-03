import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:musicplayer/services/audioc_manager.dart';
import 'package:musicplayer/services/notification_service.dart';
import '../models/music_model.dart';
import '../services/playlist_service.dart'; 
import 'dart:io';
// import 'edit_music_screen.dart';
import '../models/playlist_model.dart';
import 'dart:math';
import 'package:musicplayer/services/current_song_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayerScreen extends StatefulWidget {
  final List<Music> playlist;
  final int initialIndex;
  static List<Music> _musicList = [];

  const MusicPlayerScreen(
      {Key? key, required this.playlist, required this.initialIndex})
      : super(key: key);

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late int currentIndex;
  final AudioManager _audioManager = AudioManager();
  bool isPlaying = false;
  bool isRandomMode = false;
  final Random _random = Random();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<Playlist> playlists = [];
  bool isSongChanging = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _restoreRandomMode();
    PlayerState currentState = _audioManager.audioPlayer.state;
    _loadPlaylists();
    _attachAudioListeners();

    if (currentState == PlayerState.playing) {
      isPlaying = true;
    } else {
      isPlaying = false; 
    }

    if (currentState == PlayerState.stopped) {
      _playCurrentSong();
    }

    _audioManager.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  void _attachAudioListeners() {
    _audioManager.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioManager.audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _audioManager.audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _audioManager.audioPlayer.onPlayerComplete.listen((_) {
      _next();
    });
  }

  @override
  void dispose() {
    _audioManager.audioPlayer.onPositionChanged
        .drain(); 
    _audioManager.audioPlayer.onDurationChanged.drain();
    _audioManager.audioPlayer.onPlayerComplete.drain();
    super.dispose();
  }

  void _loadPlaylists() async {
    List<Playlist> loadedPlaylists = await PlaylistService.loadPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });
  }

  void _playCurrentSong() async {
    String filePath = widget.playlist[currentIndex].url;

    if (!File(filePath).existsSync()) {
      print("❌ File does not exist: $filePath");
      return;
    }

    print("🎵 Playing: $filePath");

    try {
      await _audioManager.play(filePath);
      setState(() {
        isPlaying = _audioManager.audioPlayer.state == PlayerState.playing;
        _position = Duration.zero;
      });

      _audioManager.audioPlayer.getDuration().then((dur) {
        if (mounted && dur != null) {
          setState(() {
            _duration = dur;
          });
        }
      });
    } catch (e) {
      print("❌ Error playing audio: $e");
    }
  }

  void _playPause() async {
    bool currentlyPlaying =
        _audioManager.audioPlayer.state == PlayerState.playing;

    if (currentlyPlaying) {
      await _audioManager.pause();
    } else {
      await _audioManager.audioPlayer
          .resume(); 
    }

    setState(() {
      isPlaying = !currentlyPlaying; 
    });
  }

  void _next() {
    if (isSongChanging)
      return;
    setState(() {
      isSongChanging = true;
    });

    int nextIndex;

    if (isRandomMode) {
      do {
        nextIndex = _random.nextInt(widget.playlist.length);
      } while (nextIndex == currentIndex);
    } else {
      nextIndex = (currentIndex + 1) % widget.playlist.length;
    }

    setState(() {
      currentIndex = nextIndex;
      _duration = Duration.zero;
      _position = Duration.zero;
    });
    var _musicList = widget.playlist;
    NotificationService.showMusicNotification(
      _musicList[currentIndex].title,
      _musicList[currentIndex].album,
      isPlaying: isPlaying,
    );
    _playCurrentSong();
  }

  void _back() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    } else {
      setState(() {
        currentIndex = widget.playlist.length - 1;
      });
    }

    var _musicList = widget.playlist;
    NotificationService.showMusicNotification(
      _musicList[currentIndex].title,
      _musicList[currentIndex].album,
      isPlaying: isPlaying,
    );
    _playCurrentSong();
    setState(() {
      isSongChanging = false;
    });
  }

  Future<void> _addToPlaylist() async {
    Playlist? selectedPlaylist = await _showSelectPlaylistDialog();
    if (selectedPlaylist != null) {
      Music currentSong = widget.playlist[currentIndex];

      // Find the correct playlist in `playlists` by name
      int playlistIndex =
          playlists.indexWhere((p) => p.name == selectedPlaylist.name);

      if (playlistIndex != -1) {
        // Check if song already exists in the found playlist
        bool alreadyExists = playlists[playlistIndex]
            .songs
            .any((song) => song.url == currentSong.url);

        if (alreadyExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "❌ '${currentSong.title}' is already in '${playlists[playlistIndex].name}'!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            playlists[playlistIndex].songs.add(currentSong);
          });

          // Save updated playlists
          await PlaylistService.savePlaylists(playlists);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "✅ Added '${currentSong.title}' to '${playlists[playlistIndex].name}'!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print("❌ Playlist not found in the list!");
      }
    }
  }

  Future<Playlist?> _showSelectPlaylistDialog() {
    return showDialog<Playlist>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Playlist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: playlists.map((playlist) {
                return ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    Navigator.of(context).pop(playlist);
                  },
                );
              }).toList(),
            ),
          );
        });
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ValueListenableBuilder<Duration>(
          valueListenable: CurrentSongService.positionNotifier,
          builder: (context, position, child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: CurrentSongService.durationNotifier,
              builder: (context, duration, child) {
                double max =
                    duration.inSeconds.toDouble().clamp(1, double.infinity);
                double current = position.inSeconds.toDouble().clamp(0, max);

                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: max,
                      value: current,
                      onChanged: (value) async {
                        Duration newPosition = Duration(seconds: value.toInt());
                        await CurrentSongService.seekTo(
                            newPosition); // Use the public method instead
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey.shade600,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position),
                            style: const TextStyle(color: Colors.white)),
                        Text(_formatDuration(duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }

  Future<void> _toggleRandomMode() async {
    setState(() {
      isRandomMode = !isRandomMode;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRandomMode', isRandomMode);
  }
  void _restoreRandomMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isRandomMode = prefs.getBool('isRandomMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist[currentIndex].title,
            style: const TextStyle(color: Colors.white)),
        backgroundColor:
            const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
        elevation: 0,
        centerTitle: true,
        actions: const [
          // IconButton(
          //   icon: const Icon(Icons.edit, color: Colors.white),
          //   onPressed: () async {
          //     final updatedSong = await Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => EditMusicScreen(
          //           music: widget.playlist[currentIndex],
          //           onSave: (updatedMusic) {
          //             setState(() {
          //               widget.playlist[currentIndex] = updatedMusic;
          //             });
          //           },
          //         ),
          //       ),
          //     );
          //     if (updatedSong != null) {
          //       setState(() {
          //         widget.playlist[currentIndex] = updatedSong;
          //       });
          //     }
          //   },
          // ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFFFFCDD2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.playlist[currentIndex].coverPhoto),
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset("assets/default_cover.png",
                        width: 250, height: 250);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                widget.playlist[currentIndex].title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgressBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isRandomMode ? Icons.shuffle_on : Icons.shuffle,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: _toggleRandomMode, 
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        size: 40, color: Colors.white),
                    onPressed: _back,
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          color: Colors.black,
                        ),
                        onPressed: _playPause,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        size: 40, color: Colors.white),
                    onPressed: _next,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        size: 40, color: Colors.white),
                    onPressed: _addToPlaylist, 
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
