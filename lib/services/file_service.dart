import 'dart:io';

Future<String?> renameSongFile(String oldPath, String newFileName) async {
  File oldFile = File(oldPath);
  String directory = oldFile.parent.path; 
  String newPath = "$directory/$newFileName.mp3";

  try {
    File newFile = await oldFile.rename(newPath);
    print("✅ File renamed to: ${newFile.path}");
    return newFile.path;
  } catch (e) {
    print("❌ Error renaming file: $e");
    return null;
  }
}
