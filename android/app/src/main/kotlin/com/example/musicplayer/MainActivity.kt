package com.example.musicplayer

import android.database.Cursor
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAudioFiles") {
                val audioList = getAudioFiles()
                result.success(audioList)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getAudioFiles(): List<Map<String, String>> {
        val audioList = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,      // File path
            MediaStore.Audio.Media.TITLE,     // Song title
            MediaStore.Audio.Media.ALBUM,     // Album name
            MediaStore.Audio.Media.DURATION   // Song duration (in milliseconds)
        )

        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        val cursor: Cursor? = contentResolver.query(
            uri,
            projection,
            selection,
            null,
            MediaStore.Audio.Media.TITLE + " ASC"
        )

        if (cursor == null || !cursor.moveToFirst()) {
            println("❌ No music files found!")
            return emptyList()
        }

        cursor.use {
            val pathColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (it.moveToNext()) {
                val path = it.getString(pathColumn)
                val title = it.getString(titleColumn) ?: "Unknown Title"
                val album = it.getString(albumColumn) ?: "Unknown Album"
                val duration = it.getLong(durationColumn)  // Get duration in milliseconds

                // 🔴 Skip songs that are too short (less than 2 seconds)
                if (duration < 2000) {
                    println("⚠️ Skipping Short Song: $title (Duration: ${duration}ms)")
                    continue  // Skip this file
                }

                println("✅ Found Music: $title - $album (Duration: ${duration}ms) [$path]")  // Debugging Log

                audioList.add(
                    mapOf(
                        "path" to path,
                        "title" to title,
                        "album" to album
                    )
                )
            }
        }
        return audioList
    }
}
