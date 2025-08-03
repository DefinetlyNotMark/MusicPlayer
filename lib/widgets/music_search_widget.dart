import 'package:flutter/material.dart';
import 'package:musicplayer/services/current_song_service.dart';
import 'package:musicplayer/views/music_player_screen.dart';
import '../models/music_model.dart';

class MusicSearchWidget extends StatefulWidget {
  final List<Music> musicFiles;
  final Function(List<Music>) onSearchResults;

  const MusicSearchWidget({
    Key? key,
    required this.musicFiles,
    required this.onSearchResults,
  }) : super(key: key);

  @override
  _MusicSearchWidgetState createState() => _MusicSearchWidgetState();
}

class _MusicSearchWidgetState extends State<MusicSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  List<Music> _filteredList = [];

  void _filterMusicList(String query) {
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _filteredList = widget.musicFiles
        .where((music) =>
            music.title.toLowerCase().contains(query.toLowerCase()) ||
            music.album.toLowerCase().contains(query.toLowerCase()))
        .toList();

    widget.onSearchResults(_filteredList);

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: offset.dy + renderBox.size.height + 5, 
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final song = _filteredList[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.album),
                      onTap: () {
                        _searchController.text = song.title;
                        _removeOverlay(); 

                        CurrentSongService.setCurrentSong(
                            song, widget.musicFiles.indexOf(song));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicPlayerScreen(
                              playlist: widget.musicFiles, 
                              initialIndex: widget.musicFiles.indexOf(song),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: "Search Songs",
          hintText: "Enter song title or album",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onChanged: _filterMusicList,
      ),
    );
  }
}
