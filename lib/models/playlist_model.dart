import 'package:musicplayer/models/music_model.dart';
class Playlist {
  final String name;
   List<Music> songs;

  Playlist({required this.name, required this.songs});

 Map<String, dynamic> toJson() {
    return {
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
    };
  }

   factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      songs: (json['songs'] as List).map((item) => Music.fromJson(item)).toList(),
    );
  }
}
