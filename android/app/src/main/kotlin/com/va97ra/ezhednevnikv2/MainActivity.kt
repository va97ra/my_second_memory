package com.va97ra.ezhednevnikv2

import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.OpenableColumns
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.time.ZoneId

class MainActivity : FlutterFragmentActivity() {
    private var pendingSoundResult: MethodChannel.Result? = null

    private val audioFilePicker = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        val result = pendingSoundResult ?: return@registerForActivityResult
        pendingSoundResult = null
        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            val name = displayName(uri) ?: "Мелодия будильника"
            val storedUri = copyAudioToNotifications(uri, name)
            result.success(mapOf("uri" to storedUri.toString(), "name" to name))
        } catch (error: Exception) {
            result.error("audio_file_unavailable", error.message, null)
        }
    }

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
            if (call.method != "saveBackupToDownloads" &&
                call.method != "saveBackupFileToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val fileName = call.argument<String>("fileName") ?: "ezhednevnik_v2_backup.zip"
                if (call.method == "saveBackupFileToDownloads") {
                    val sourcePath = call.argument<String>("sourcePath")
                        ?: throw IllegalArgumentException("Missing source path")
                    result.success(saveFileToDownloads(fileName, File(sourcePath)))
                } else {
                    val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                    result.success(saveToDownloads(fileName, bytes))
                }
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
                "listSystemAlarmSounds" -> listSystemAlarmSounds(result)
                "selectReminderSound" -> selectReminderSound(
                    call.argument<String>("currentUri"),
                    result
                )
                "selectReminderAudioFile" -> selectReminderAudioFile(result)
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

    private fun listSystemAlarmSounds(result: MethodChannel.Result) {
        try {
            val sounds = mutableListOf<Map<String, String>>()
            val seen = mutableSetOf<String>()
            val defaultUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (defaultUri != null) {
                val uri = defaultUri.toString()
                seen.add(uri)
                sounds.add(mapOf("uri" to uri, "name" to "По умолчанию"))
            }

            val manager = RingtoneManager(this).apply {
                setType(RingtoneManager.TYPE_ALARM)
            }
            manager.cursor.use { cursor ->
                var position = 0
                while (cursor.moveToNext()) {
                    val soundUri = manager.getRingtoneUri(position++) ?: continue
                    val uri = soundUri.toString()
                    if (!seen.add(uri)) continue
                    val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                    sounds.add(
                        mapOf(
                            "uri" to uri,
                            "name" to (title ?: "Системный звук")
                        )
                    )
                }
            }
            result.success(sounds)
        } catch (error: Exception) {
            result.error("sounds_unavailable", error.message, null)
        }
    }

    private fun selectReminderAudioFile(result: MethodChannel.Result) {
        if (pendingSoundResult != null) {
            result.error("picker_busy", "Sound picker is already open", null)
            return
        }
        pendingSoundResult = result
        try {
            audioFilePicker.launch(arrayOf("audio/*"))
        } catch (error: Exception) {
            pendingSoundResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    private fun displayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) return cursor.getString(index)
                }
            }
        return null
    }

    private fun copyAudioToNotifications(source: Uri, originalName: String): Uri {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return source
        }
        val safeName = originalName.replace(Regex("[^a-zA-Zа-яА-Я0-9._ -]"), "_")
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
            put(
                MediaStore.MediaColumns.MIME_TYPE,
                contentResolver.getType(source) ?: "audio/mpeg"
            )
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_NOTIFICATIONS}/Ezhednevnik V2"
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val target = contentResolver.insert(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            values
        ) ?: throw IllegalStateException("Cannot create notification sound")
        try {
            contentResolver.openInputStream(source)?.use { input ->
                contentResolver.openOutputStream(target)?.use { output ->
                    input.copyTo(output)
                } ?: throw IllegalStateException("Cannot write notification sound")
            } ?: throw IllegalStateException("Cannot read selected audio")
            contentResolver.update(
                target,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )
            return target
        } catch (error: Exception) {
            contentResolver.delete(target, null, null)
            throw error
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
        return saveStreamToDownloads(fileName) { output -> output.write(bytes) }
    }

    private fun saveFileToDownloads(fileName: String, source: File): String {
        return saveStreamToDownloads(fileName) { output ->
            source.inputStream().use { input -> input.copyTo(output) }
        }
    }

    private fun saveStreamToDownloads(
        fileName: String,
        writer: (java.io.OutputStream) -> Unit
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/zip")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Cannot create download file")
            contentResolver.openOutputStream(uri)?.use { output ->
                writer(output)
            } ?: throw IllegalStateException("Cannot open download file")
            return "Загрузки/$fileName"
        }

        val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!directory.exists()) {
            directory.mkdirs()
        }
        val file = File(directory, fileName)
        file.outputStream().use(writer)
        return file.absolutePath
    }
}
