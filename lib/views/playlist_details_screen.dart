import 'package:flutter/material.dart';
import 'package:musicplayer/models/playlist_model.dart';
import 'package:musicplayer/models/music_model.dart';
import 'package:musicplayer/views/music_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicplayer/services/playlist_service.dart';
import 'dart:convert';
import 'package:musicplayer/services/current_song_service.dart';
import '../widgets/current_song_widget.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;

  PlaylistDetailsScreen({required this.playlist});

  @override
  _PlaylistDetailsScreenState createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  late Playlist playlist;

  @override
  void initState() {
    super.initState();
    playlist =
        widget.playlist;
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    String? playlistJson = prefs.getString('playlist_${playlist.name}');

    if (playlistJson != null) {
      Playlist loadedPlaylist = Playlist.fromJson(jsonDecode(playlistJson));
      setState(() {
        playlist =
            loadedPlaylist;
      });
    }
  }

  Future<void> _removeSong(int index) async {
    setState(() {
      playlist.songs.removeAt(index); 
    });

    await _savePlaylist();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Song removed from playlist"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _savePlaylist() async {
    List<Playlist> playlists = await PlaylistService.loadPlaylists();

    int playlistIndex = playlists.indexWhere((p) => p.name == playlist.name);

    if (playlistIndex != -1) {
      playlists[playlistIndex] = playlist;
    }

    await PlaylistService.savePlaylists(
        playlists); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
        title: Text(
          widget.playlist.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Stack(children: [
         playlist.songs.isEmpty ? _buildEmptyPlaylist() : _buildSongList(),
              CurrentSongWidget(
                  playlist: CurrentSongService
                      .getActiveMusicList(),
                ),
      ]),
    );
  }

  Widget _buildEmptyPlaylist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 60,
            color: const Color.fromARGB(255, 251, 251, 251).withOpacity(0.6),
          ),
          SizedBox(height: 20),
          Text(
            "No songs in this playlist",
            style: TextStyle(
              fontSize: 18,
              color: const Color.fromARGB(255, 160, 158, 158),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return Padding(
       padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      child: ListView.builder(
        itemCount: playlist.songs.length,
        itemBuilder: (context, index) {
          Music song = playlist.songs[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              leading: Icon(
                Icons.music_note,
                color: Colors.pinkAccent,
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                song.album,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                CurrentSongService.setMusicList(playlist.songs);
                CurrentSongService.setPlaylistScreenActive(true);
                CurrentSongService.setCurrentSong(playlist.songs[index], index);

                setState(() {});

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerScreen(
                      playlist: playlist.songs,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _removeSong(index);
                },
              ),
            ),
          );
        },
      ),
    );
    
  }
}
