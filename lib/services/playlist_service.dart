import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicplayer/models/playlist_model.dart';

class PlaylistService {
 static Future<List<Playlist>> loadPlaylists() async {
  final prefs = await SharedPreferences.getInstance();
  String? playlistsJson = prefs.getString("playlists");

  if (playlistsJson != null) {
    List<dynamic> decoded = jsonDecode(playlistsJson);
    return decoded.map((p) => Playlist.fromJson(p)).toList();
  }

  return [];
}


  static Future<void> savePlaylists(List<Playlist> playlists) async {
  final prefs = await SharedPreferences.getInstance();
  String playlistsJson = jsonEncode(playlists.map((p) => p.toJson()).toList());
  await prefs.setString("playlists", playlistsJson);
}

}