import 'package:flutter/material.dart';
import 'package:musicplayer/models/playlist_model.dart';
import 'package:musicplayer/services/playlist_service.dart'; // Import PlaylistService
import 'playlist_details_screen.dart';

class PlaylistManagementScreen extends StatefulWidget {
  final List<Playlist> playlists; // Add the playlists parameter
  final Function(Playlist) onPlaylistCreated;

  PlaylistManagementScreen(
      {required this.playlists, required this.onPlaylistCreated});

  @override
  _PlaylistManagementScreenState createState() =>
      _PlaylistManagementScreenState();
}

class _PlaylistManagementScreenState extends State<PlaylistManagementScreen> {
  List<Playlist> playlists = [];
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    playlists = widget.playlists;
    _loadPlaylists();
  }

  void _loadPlaylists() async {
    List<Playlist> loadedPlaylists = await PlaylistService.loadPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });

    print("Loaded Playlists: $playlists");
  }

  void _savePlaylists() {
    PlaylistService.savePlaylists(playlists);
  }

  void _createPlaylist() {
    String playlistName = _playlistNameController.text.trim();

    if (playlistName.isEmpty) {
      return;
    }

    Playlist newPlaylist = Playlist(name: playlistName, songs: []);

    setState(() {
      playlists.add(newPlaylist);
    });

    _savePlaylists();

    print("New Playlist Created: ${newPlaylist.name}");
    print("Current Playlists: $playlists");

    _playlistNameController.clear();
    setState(() {
      
    });
  }

  void _deletePlaylist(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Playlist"),
          content: Text("Are you sure you want to delete this playlist?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  playlists.removeAt(index);
                });
                _savePlaylists();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
        title: const Text("Manage Playlists"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(
                labelText: "Enter Playlist Name",
                labelStyle:
                    TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createPlaylist,
              style: ElevatedButton.styleFrom(
                primary: Colors.pinkAccent,
                onPrimary: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Create Playlist",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
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
                        Icons.playlist_play,
                        color: Colors.pinkAccent,
                      ),
                      title: Text(
                        playlists[index].name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deletePlaylist(index),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistDetailsScreen(
                                playlist: playlists[index]),
                          ),
                        ).then((_) {
                          _loadPlaylists(); // 
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
