package com.va97ra.ezhednevnikv2

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * Голос Джарвиса в момент напоминания — даже когда приложение закрыто.
 *
 * Уведомление показывает flutter_local_notifications, а здесь — только голос
 * на то же время: свой будильник AlarmManager с тем же id. Будильник с
 * мелодией голос не перебивает: ждёт, пока мелодию выключат, и звучит сразу
 * за ней. Запланированное хранится в SharedPreferences и после перезагрузки
 * или обновления ставится заново. Молчит в беззвучном режиме, при «Не
 * беспокоить» и во время звонка.
 *
 * Канал ezhednevnik_v2/speak (spoken_reminders.dart): sync, put, remove,
 * setEnabled. Перенесено из MemoryVoice, где проверено на телефоне владельца.
 */
object SpokenReminders {
    const val PREFS = "spoken_reminders"
    private const val KEY_ITEMS = "items"
    private const val KEY_ENABLED = "enabled"

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "ezhednevnik_v2/speak").setMethodCallHandler { call, result ->
            try {
                saveTone(app, call.argument<List<String>>("voices"),
                    call.argument<Double>("pitch"), call.argument<Double>("rate"))
                when (call.method) {
                    "sync" -> sync(app, call.argument<String>("group")!!,
                        call.argument<List<Map<String, Any?>>>("items") ?: emptyList())
                    "put" -> put(app, call.argument<String>("group")!!,
                        call.argument<Int>("id")!!, call.argument<Number>("at")!!.toLong(),
                        call.argument<String>("text") ?: "")
                    "remove" -> remove(app, call.argument<Int>("id")!!)
                    "setEnabled" -> prefs(app).edit()
                        .putBoolean(KEY_ENABLED, call.argument<Boolean>("enabled") ?: true).apply()
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                result.success(null)
            } catch (e: Exception) {
                result.error("speak", e.message, null)
            }
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun saveTone(context: Context, voices: List<String>?, pitch: Double?, rate: Double?) {
        val edit = prefs(context).edit()
        if (voices != null) edit.putString("voices", JSONArray(voices).toString())
        if (pitch != null) edit.putFloat("pitch", pitch.toFloat())
        if (rate != null) edit.putFloat("rate", rate.toFloat())
        edit.apply()
    }

    private fun items(context: Context): JSONObject = try {
        JSONObject(prefs(context).getString(KEY_ITEMS, "{}") ?: "{}")
    } catch (e: Exception) {
        JSONObject()
    }

    private fun save(context: Context, items: JSONObject) =
        prefs(context).edit().putString(KEY_ITEMS, items.toString()).apply()

    /** Группа целиком: чего нет в [wanted], то снимается. */
    private fun sync(context: Context, group: String, wanted: List<Map<String, Any?>>) {
        val all = items(context)
        val keep = mutableSetOf<String>()
        for (entry in wanted) {
            val id = (entry["id"] as Number).toInt()
            val at = (entry["at"] as Number).toLong()
            val text = entry["text"] as? String ?: ""
            if (at <= System.currentTimeMillis() || text.isBlank()) continue
            keep.add(id.toString())
            all.put(id.toString(), JSONObject().put("at", at).put("text", text).put("group", group))
            setAlarm(context, id, at)
        }
        val now = System.currentTimeMillis()
        for (key in all.keys().asSequence().toList()) {
            val item = all.optJSONObject(key) ?: continue
            // Голос, который ждёт, пока выключат мелодию, уже не в будущем, но
            // ещё нужен — его не снимаем.
            if (item.optLong("waitUntil", 0L) > now) continue
            if (item.optString("group") == group && key !in keep) {
                all.remove(key)
                cancelAlarm(context, key.toInt())
            }
        }
        save(context, all)
    }

    private fun put(context: Context, group: String, id: Int, at: Long, text: String) {
        if (at <= System.currentTimeMillis() || text.isBlank()) {
            remove(context, id)
            return
        }
        val all = items(context)
        all.put(id.toString(), JSONObject().put("at", at).put("text", text).put("group", group))
        save(context, all)
        setAlarm(context, id, at)
    }

    private fun remove(context: Context, id: Int) {
        val all = items(context)
        if (all.has(id.toString())) {
            all.remove(id.toString())
            save(context, all)
        }
        cancelAlarm(context, id)
    }

    /** Дольше этого мелодию будильника не ждём: его так и не выключили. */
    private const val WAIT_FOR_ALARM_MS = 30 * 60 * 1000L
    private const val RECHECK_MS = 15_000L

    /** Звенит ли ещё наш будильник с этим id: уведомление с мелодией висит,
     * пока не нажмут «Выключить звук» или «Открыть». */
    fun alarmRinging(context: Context, id: Int): Boolean =
        context.getSystemService(NotificationManager::class.java).activeNotifications.any {
            it.id == id && it.notification.flags and Notification.FLAG_INSISTENT != 0
        }

    /** Будильник ещё звенит — спросить снова чуть позже; ждём не вечно. */
    fun waitForAlarm(context: Context, id: Int) {
        val all = items(context)
        val item = all.optJSONObject(id.toString()) ?: return
        val now = System.currentTimeMillis()
        val until = item.optLong("waitUntil", 0L).takeIf { it > 0 }
            ?: (now + WAIT_FOR_ALARM_MS).also { item.put("waitUntil", it) }
        if (now > until) {
            all.remove(id.toString())
            save(context, all)
            return
        }
        item.put("at", now + RECHECK_MS)
        save(context, all)
        setAlarm(context, id, now + RECHECK_MS)
    }

    /** Сработал будильник: текст, если он ещё нужен; запись снимается. */
    fun take(context: Context, id: Int): String? {
        val all = items(context)
        val item = all.optJSONObject(id.toString()) ?: return null
        all.remove(id.toString())
        save(context, all)
        return item.optString("text").takeIf { it.isNotBlank() }
    }

    /** После перезагрузки и обновления будильники сняты — будущие ставятся заново. */
    fun restore(context: Context) {
        val all = items(context)
        val now = System.currentTimeMillis()
        for (key in all.keys().asSequence().toList()) {
            val at = all.optJSONObject(key)?.optLong("at") ?: 0L
            if (at > now) setAlarm(context, key.toInt(), at) else all.remove(key)
        }
        save(context, all)
    }

    fun enabled(context: Context) = prefs(context).getBoolean(KEY_ENABLED, true)

    private fun pending(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context, id,
        Intent(context, SpeakReceiver::class.java).putExtra("id", id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun setAlarm(context: Context, id: Int, at: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val intent = pending(context, id)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun cancelAlarm(context: Context, id: Int) =
        context.getSystemService(AlarmManager::class.java).cancel(pending(context, id))

    /** Можно ли сейчас говорить: звук включён, нет «Не беспокоить», нет звонка. */
    fun canSpeakNow(context: Context): Boolean {
        val audio = context.getSystemService(AudioManager::class.java)
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return false
        if (audio.mode == AudioManager.MODE_IN_CALL ||
            audio.mode == AudioManager.MODE_IN_COMMUNICATION) return false
        val filter = context.getSystemService(NotificationManager::class.java)
            .currentInterruptionFilter
        return filter == NotificationManager.INTERRUPTION_FILTER_ALL ||
            filter == NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }
}

/** Сработал будильник голоса, или телефон перезагрузился. */
class SpeakReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                SpokenReminders.restore(app)
                return
            }
        }
        val id = intent.getIntExtra("id", -1)
        val result = goAsync()
        // Сначала звучит само уведомление; будильник с мелодией — пока его
        // не выключат.
        Handler(Looper.getMainLooper()).postDelayed({
            if (SpokenReminders.alarmRinging(app, id)) {
                SpokenReminders.waitForAlarm(app, id)
                result.finish()
                return@postDelayed
            }
            val text = SpokenReminders.take(app, id)
            if (text == null || !SpokenReminders.enabled(app) ||
                !SpokenReminders.canSpeakNow(app)) {
                result.finish()
                return@postDelayed
            }
            ReminderSpeaker.speak(app, text) { result.finish() }
        }, AFTER_NOTIFICATION_MS)
    }

    private companion object {
        const val AFTER_NOTIFICATION_MS = 2000L
    }
}

/** Синтез речи голосом Джарвиса: голос, тон и темп присылает приложение. */
object ReminderSpeaker {
    fun speak(context: Context, text: String, done: () -> Unit) {
        val prefs = context.getSharedPreferences(SpokenReminders.PREFS, Context.MODE_PRIVATE)
        val voices = try {
            JSONArray(prefs.getString("voices", "[]")).let { list ->
                (0 until list.length()).map { list.getString(it) }
            }
        } catch (e: Exception) {
            emptyList()
        }
        val pitch = prefs.getFloat("pitch", 1f)
        val rate = prefs.getFloat("rate", 0.5f)
        val handler = Handler(Looper.getMainLooper())
        val audio = context.getSystemService(AudioManager::class.java)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        val focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes)
            .build()
        var tts: TextToSpeech? = null
        var finished = false
        fun finish() {
            if (finished) return
            finished = true
            audio.abandonAudioFocusRequest(focus)
            tts?.shutdown()
            done()
        }
        // Что бы ни случилось с движком речи — через 30 с отпускаем.
        handler.postDelayed({ finish() }, 30_000)
        tts = TextToSpeech(context) { status ->
            val engine = tts
            if (status != TextToSpeech.SUCCESS || engine == null) {
                finish()
                return@TextToSpeech
            }
            engine.language = Locale("ru", "RU")
            val installed = try { engine.voices ?: emptySet() } catch (e: Exception) { emptySet() }
            voices.firstNotNullOfOrNull { name -> installed.firstOrNull { it.name == name } }
                ?.let { engine.voice = it }
            engine.setPitch(pitch)
            // Мерка flutter_tts: 0,5 — обычная речь, у Android обычная — 1.
            engine.setSpeechRate(rate * 2f)
            engine.setAudioAttributes(attributes)
            engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) { handler.post { finish() } }
                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) { handler.post { finish() } }
            })
            audio.requestAudioFocus(focus)
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "reminder")
        }
    }
}
