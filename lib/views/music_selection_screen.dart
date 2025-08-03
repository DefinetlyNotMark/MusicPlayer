import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musicplayer/views/webview.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'dart:io';
import '../widgets/current_song_widget.dart';
import '../widgets/music_search_widget.dart';
import '../models/music_model.dart';
import '../views/playlist_selection_screen.dart';
import '../models/playlist_model.dart';
import '../views/music_player_screen.dart';
import '../services/playlist_service.dart';
import '../services/current_song_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MusicSelectionScreen extends StatefulWidget {
  const MusicSelectionScreen({Key? key}) : super(key: key);

  @override
  _MusicSelectionScreenState createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  Future<List<Music>>? _musicFuture;
  List<Playlist> playlists = [];

  @override
  void initState() {
    super.initState();
    CurrentSongService.init();
    _musicFuture = Future.value([]);
    _loadPlaylists();
    _checkAndRequestPermission().then((_) {
      _musicFuture = _scanMusicFiles();
    });
  }

  Future<void> _checkAndRequestPermission() async {}



  Future<void> _refreshContent() async {
    await _loadPlaylists();
    _musicFuture = _scanMusicFiles();
    setState(() {}); 
  }

  Future<void> _loadPlaylists() async {
    playlists = await PlaylistService
        .loadPlaylists(); 
    setState(() {}); 
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

  Future<List<Music>> _scanMusicFiles() async {
    List<Music> musicList = [];
    const platform = MethodChannel('media_store');

    try {
      final List<dynamic> result = await platform.invokeMethod('getAudioFiles');

      Map<String, List<Music>> folderGroups = {};

      for (var item in result) {
        String filePath = item['path'];
        final metadata = await MetadataRetriever.fromFile(File(filePath));

        if (metadata.trackDuration != null && metadata.trackDuration! > 2000) {
          Music song = Music(
            title: item['title'] ?? "Unknown Title",
            url: filePath,
            album: item['album'] ?? "Unknown Album",
            coverPhoto: "assets/default_cover.png",
          );
          String folderPath = Directory(filePath).parent.path;
          if (!folderGroups.containsKey(folderPath)) {
            folderGroups[folderPath] = [];
          }
          folderGroups[folderPath]?.add(song);
        } else {
          print("⚠️ Skipping short/invalid file: $filePath");
        }
      }
      folderGroups.forEach((folder, songs) {
        songs.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        musicList.addAll(songs);
      });
    } on PlatformException catch (e) {
      print("❌ Failed to load media: $e");
    }

    print("✅ Loaded ${musicList.length} valid songs.");
    return musicList;
  }

  Future<void> _addSongToPlaylist(Music song) async {
    Playlist? selectedPlaylist = await _showSelectPlaylistDialog();
    if (selectedPlaylist != null) {
    
      int playlistIndex =
          playlists.indexWhere((p) => p.name == selectedPlaylist.name);

      if (playlistIndex != -1) {
        bool isDuplicate =
            playlists[playlistIndex].songs.any((s) => s.url == song.url);

        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "❌ This song is already in ${playlists[playlistIndex].name}!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            playlists[playlistIndex].songs.add(song);
          });

          await PlaylistService.savePlaylists(
              playlists); 

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "🎶 Added '${song.title}' to ${playlists[playlistIndex].name}!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print("❌ Playlist not found in list!");
      }
    }
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    String playlistsJson =
        jsonEncode(playlists.map((p) => p.toJson()).toList());
    await prefs.setString("playlists", playlistsJson);
  }

  void _navigateToPlaylistManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistManagementScreen(
          playlists: playlists,
          onPlaylistCreated: (playlist) {
            setState(() {
              playlists.add(playlist);
            });
          },
        ),
      ),
    );
    setState(() {});
    _loadPlaylists();
  }

  void _navigateWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecureWebView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
        title:
            const Text("Select Music", style: TextStyle(color: Colors.white)),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 226, 181, 165),
              ),
              child: Text(
                'Music App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Manage Playlists'),
              onTap: () {
                Navigator.pop(context); 
                _navigateToPlaylistManagement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Web View'),
              onTap: () {
                Navigator.pop(context);
                _navigateWebView();
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Music>>(
        future: _musicFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("❌ Error loading music!"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            Future.delayed(const Duration(seconds: 3), () {
              setState(() {
                _refreshContent();
              });
            });
            return const Center(child: Text("No music found!"));
          }

          final musicFiles = snapshot.data!;

          return RefreshIndicator(
            onRefresh:
                _refreshContent, 
            child: Stack(
              children: [
                Column(
                  children: [
                    MusicSearchWidget(
                      musicFiles: musicFiles,
                      onSearchResults: (filteredList) {
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: musicFiles.length,
                        itemBuilder: (context, index) {
                          final song = musicFiles[index];
                          return Column(
                            children: [
                              ListTile(
                                title: Text(song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(song.album,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  if (musicFiles.isNotEmpty) {
                                    CurrentSongService.setMusicList(
                                        musicFiles);
                                    CurrentSongService.setCurrentSong(
                                        song, index);
                                    setState(() {});
                                    CurrentSongService.setPlaylistScreenActive(false);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MusicPlayerScreen(
                                          playlist: musicFiles,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  } else {
                                    debugPrint("❌ No music available to play!");
                                  }
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _addSongToPlaylist(song);
                                  },
                                ),
                              ),
                              if (index < musicFiles.length - 1)
                                const Divider(height: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30.0)
                  ],
                ),
                CurrentSongWidget(
                  playlist: CurrentSongService
                      .getActiveMusicList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
