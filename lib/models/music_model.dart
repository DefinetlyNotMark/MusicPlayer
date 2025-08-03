class Music {
  String title;
  String url;
  String coverPhoto;
  String album; // New field for album

  Music({
    required this.title,
    required this.url,
    required this.coverPhoto,
    required this.album, // Add album parameter
  });

  // Convert a Music object to a Map to store in SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'coverPhoto': coverPhoto,
      'album': album,  // Serialize the album
    };
  }

  // Convert a Map into a Music object
  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      title: json['title'],
      url: json['url'],
      coverPhoto: json['coverPhoto'],
      album: json['album'],  // Deserialize the album
    );
  }
}
