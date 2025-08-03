import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/music_model.dart';

class MusicController {
  Future<List<Music>> scanMusicFiles(BuildContext context) async {
    List<Music> musicList = [];
    String rootPath = "/storage/emulated/0/"; // ✅ Default path for VidMate

    // ✅ Request Permissions
    debugPrint("🔍 Requesting storage & audio permissions...");
    bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      debugPrint("🚫 No permission granted. Aborting scan.");
      return [];
    }

    if (!await Directory(rootPath).exists()) {
      debugPrint("❌ Directory does not exist: $rootPath");
      return [];
    }

    try {
      debugPrint("🔍 Checking storage at: $rootPath");
      Directory rootDir = Directory(rootPath);

      await for (FileSystemEntity entity in rootDir.list()) {
        if (entity is Directory) {
          String folderName = entity.path.split('/').last;
          debugPrint("📂 Found folder: $folderName");

          // ❌ Skip system/private folders
          if (folderName.toLowerCase() == "android" || folderName.toLowerCase() == "data") {
            debugPrint("🚫 Skipping restricted folder: $folderName");
            continue;
          }

          debugPrint("✅ Scanning folder: ${entity.path}");

          // ✅ If "VidMate" is found, scan its "download" folder
          if (folderName == "VidMate") {
            Directory vidmateDownload = Directory("${entity.path}/download");
            if (await vidmateDownload.exists()) {
              debugPrint("📂 Found VidMate/download, scanning...");
              await _scanFolder(vidmateDownload, musicList);
            } else {
              debugPrint("🚫 VidMate/download does not exist.");
            }
          } else {
            await _scanFolder(entity, musicList);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error scanning storage: $e");
    }

    debugPrint("🎵 Total Songs Found: ${musicList.length}");
    return musicList;
  }

  // ✅ Scan a specific folder and add MP3 files to the list
  Future<void> _scanFolder(Directory directory, List<Music> musicList) async {
    try {
      print("📂 Scanning: ${directory.path}");  // ✅ Ensure scanning starts

      await for (var file in directory.list(recursive: true, followLinks: false)) {
        if (file is File && file.path.endsWith('.mp3')) {
          print("🎵 Found MP3: ${file.path}"); // ✅ Force output
          musicList.add(
            Music(
              title: file.uri.pathSegments.last.replaceAll(".mp3", ""),
              url: file.path,
              coverPhoto: "assets/default_cover.jpg",
              album: "Unknown",
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error scanning folder: ${directory.path} - $e");
    }
  }

  // ✅ Request Storage & Audio Permissions
  Future<bool> _requestPermission() async {
    debugPrint("🔍 Requesting permissions...");
    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.audio,
    ].request();

    if (statuses[Permission.storage]!.isGranted ||
        statuses[Permission.manageExternalStorage]!.isGranted ||
        statuses[Permission.audio]!.isGranted) {
      debugPrint("✅ Permissions granted!");
      return true;
    }

    debugPrint("🚫 Permissions denied.");
    if (statuses[Permission.storage]!.isPermanentlyDenied ||
        statuses[Permission.manageExternalStorage]!.isPermanentlyDenied ||
        statuses[Permission.audio]!.isPermanentlyDenied) {
      debugPrint("⚠️ Permissions permanently denied. Opening settings...");
      openAppSettings();
    }

    return false;
  }

  // ✅ Debug: List all storage folders
  void debugStorageFolders() async {
    debugPrint("🔍 Debugging storage folders...");
    Directory rootDir = Directory("/storage/emulated/0/");
    
    await for (FileSystemEntity entity in rootDir.list()) {
      if (entity is Directory) {
        debugPrint("📂 Found folder: ${entity.path}");
      }
    }
  }
}
