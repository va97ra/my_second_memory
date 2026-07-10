package com.va97ra.ezhednevnikv2

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ezhednevnik_v2/downloads"
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveBackupToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val fileName = call.argument<String>("fileName") ?: "ezhednevnik_v2_backup.zip"
                val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                result.success(saveToDownloads(fileName, bytes))
            } catch (_: Exception) {
                result.success(null)
            }
        }
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/zip")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Cannot create download file")
            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IllegalStateException("Cannot open download file")
            return "Загрузки/$fileName"
        }

        val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!directory.exists()) {
            directory.mkdirs()
        }
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }
}
