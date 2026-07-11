package com.va97ra.ezhednevnikv2

import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.time.ZoneId

class MainActivity : FlutterFragmentActivity() {
    private var pendingSoundResult: MethodChannel.Result? = null

    private val ringtonePicker = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { activityResult ->
        val result = pendingSoundResult ?: return@registerForActivityResult
        pendingSoundResult = null

        if (activityResult.resultCode != RESULT_OK) {
            result.success(null)
            return@registerForActivityResult
        }

        val uri = pickedRingtoneUri(activityResult.data)
        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }

        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {
            // System ringtone URIs do not always expose persistable permissions.
        }

        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        } catch (_: Exception) {
            null
        }
        result.success(
            mapOf(
                "uri" to uri.toString(),
                "name" to (title ?: "Системный звук")
            )
        )
    }

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ezhednevnik_v2/notifications"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZone" -> result.success(ZoneId.systemDefault().id)
                "getDefaultAlarmSound" -> result.success(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)?.toString()
                )
                "selectReminderSound" -> selectReminderSound(
                    call.argument<String>("currentUri"),
                    result
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun selectReminderSound(currentUri: String?, result: MethodChannel.Result) {
        if (pendingSoundResult != null) {
            result.error("picker_busy", "Sound picker is already open", null)
            return
        }

        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            if (!currentUri.isNullOrBlank()) {
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        pendingSoundResult = result
        try {
            ringtonePicker.launch(intent)
        } catch (error: Exception) {
            pendingSoundResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun pickedRingtoneUri(intent: Intent?): Uri? {
        if (intent == null) return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(
                RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                Uri::class.java
            )
        } else {
            intent.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
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
