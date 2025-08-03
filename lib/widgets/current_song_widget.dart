import 'package:flutter/material.dart';
import '../services/current_song_service.dart';
import '../models/music_model.dart';
import '../views/music_player_screen.dart';

class CurrentSongWidget extends StatelessWidget {
  final List<Music> playlist;

  const CurrentSongWidget({Key? key, required this.playlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Music?>(
      valueListenable: CurrentSongService.currentSongNotifier,
      builder: (context, currentSong, _) {
        if (currentSong != null) {
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerScreen(
                      playlist: playlist,
                      initialIndex: CurrentSongService.getCurrentIndex(),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      color: Colors.white,
                      onPressed: () {
                        CurrentSongService.previousSong();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        CurrentSongService.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      color: Colors.white,
                      onPressed: () {
                        CurrentSongService.togglePlayPause();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: Colors.white,
                      onPressed: () {
                        CurrentSongService.nextSong();
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Now Playing: ${currentSong.title}",
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: () {
                        CurrentSongService.stopPlayback();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
