import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_model.dart';

class EditMusicScreen extends StatefulWidget {
  final Music music;
  final Function(Music) onSave;

  const EditMusicScreen({Key? key, required this.music, required this.onSave})
      : super(key: key);

  @override
  _EditMusicScreenState createState() => _EditMusicScreenState();
}

class _EditMusicScreenState extends State<EditMusicScreen> {
  late TextEditingController titleController;
  late TextEditingController albumController;
  String? newCoverPhoto;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.music.title);
    albumController = TextEditingController(text: widget.music.album);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String newPath = await _saveImageToAppDir(File(pickedFile.path));
      setState(() {
        newCoverPhoto = newPath;
      });
    }
  }

  /// Saves image to app's local directory
  Future<String> _saveImageToAppDir(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final newImagePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await imageFile.copy(newImagePath);
    return newImagePath;
  }

  Future<String> _renameMusicFile(String oldPath, String newTitle) async {
    File oldFile = File(oldPath);
    if (!oldFile.existsSync()) {
      return oldPath; // File doesn't exist, return original path
    }

    Directory directory = oldFile.parent;
    String newFilePath = '${directory.path}/$newTitle.mp3';

    // Check if a file with the new name already exists
    if (File(newFilePath).existsSync()) {
      int counter = 1;
      String uniqueFilePath;
      do {
        uniqueFilePath = '${directory.path}/$newTitle($counter).mp3';
        counter++;
      } while (File(uniqueFilePath).existsSync());
      newFilePath = uniqueFilePath;
    }

    File newFile = await oldFile.rename(newFilePath);
    return newFile.path;
  }

  void _saveChanges() async {
    String oldFilePath = widget.music.url;
    String newTitle = titleController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
      return;
    }

    String newFilePath = await _renameMusicFile(oldFilePath, newTitle);

    Music updatedMusic = Music(
      title: newTitle,
      url: newFilePath, // ✅ Use new path
      coverPhoto: newCoverPhoto ?? widget.music.coverPhoto,
      album: albumController.text,
    );

    widget.onSave(updatedMusic);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Music info updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 226, 181, 165).withOpacity(0.6),
        title: const Text(
          "Edit Music Info",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Cover Photo
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(newCoverPhoto ?? widget.music.coverPhoto),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset("assets/default_cover.png",
                        width: 150, height: 150);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Song Title"),
            ),
            const SizedBox(height: 10),

            // Album Field
            TextField(
              controller: albumController,
              decoration: const InputDecoration(labelText: "Album Name"),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
