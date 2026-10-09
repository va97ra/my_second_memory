package com.va97ra.ezhednevnikv2

import android.app.Activity
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Уведомления о деньгах для Джарвиса: из них он записывает расходы и доходы.
 *
 * Доступ к уведомлениям человек включает сам, в настройках телефона. Здесь
 * уведомление не разбирается — только откладывается, если в нём есть сумма с
 * валютой; банковское ли оно и что в нём, решает Ежедневник
 * (bank_notice_phrases.dart), а отложенное забывает. Пока Джарвису это не
 * разрешено в настройках приложения, ничего не откладывается.
 *
 * Канал ezhednevnik_v2/bank (jarvis_bank_notices.dart): pending, forget,
 * setEnabled, accessGranted, openAccess; приложению — noticed.
 */
object BankNotices {
    private const val PREFS = "bank_notices"
    private const val KEY_ITEMS = "items"
    private const val KEY_ENABLED = "enabled"
    private const val LIMIT = 50

    /** Сумма с валютой: «350р», «1 250,50 ₽», «500.00 RUB». */
    private val money = Regex("""\d\s?(₽|р\.?(?![а-я])|руб|rub|rur)""", RegexOption.IGNORE_CASE)

    private var channel: MethodChannel? = null

    fun register(activity: Activity, messenger: BinaryMessenger) {
        val app = activity.applicationContext
        val bank = MethodChannel(messenger, "ezhednevnik_v2/bank")
        channel = bank
        bank.setMethodCallHandler { call, result ->
            when (call.method) {
                "pending" -> result.success(pending(app))
                "forget" -> {
                    forget(app, call.argument<List<String>>("keys") ?: emptyList())
                    result.success(null)
                }
                "setEnabled" -> {
                    prefs(app).edit()
                        .putBoolean(KEY_ENABLED, call.argument<Boolean>("enabled") ?: false).apply()
                    result.success(null)
                }
                "accessGranted" -> result.success(
                    NotificationManagerCompat.getEnabledListenerPackages(app).contains(app.packageName)
                )
                "openAccess" -> {
                    activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun items(context: Context): JSONArray = try {
        JSONArray(prefs(context).getString(KEY_ITEMS, "[]") ?: "[]")
    } catch (e: Exception) {
        JSONArray()
    }

    fun keep(context: Context, key: String, app: String, title: String, text: String, at: Long) {
        val settings = prefs(context)
        if (!settings.getBoolean(KEY_ENABLED, false)) return
        if (!money.containsMatchIn("$title $text")) return
        val all = items(context)
        for (i in 0 until all.length()) {
            if (all.optJSONObject(i)?.optString("key") == key) return
        }
        all.put(JSONObject().put("key", key).put("app", app).put("title", title)
            .put("text", text).put("at", at))
        val kept = JSONArray()
        for (i in maxOf(0, all.length() - LIMIT) until all.length()) kept.put(all.get(i))
        settings.edit().putString(KEY_ITEMS, kept.toString()).apply()
        // Приложение открыто — пусть разберёт сразу.
        Handler(Looper.getMainLooper()).post { channel?.invokeMethod("noticed", null) }
    }

    private fun pending(context: Context): List<Map<String, Any>> {
        val all = items(context)
        return (0 until all.length()).mapNotNull { i ->
            val item = all.optJSONObject(i) ?: return@mapNotNull null
            mapOf(
                "key" to item.optString("key"),
                "app" to item.optString("app"),
                "title" to item.optString("title"),
                "text" to item.optString("text"),
                "at" to item.optLong("at"),
            )
        }
    }

    private fun forget(context: Context, keys: List<String>) {
        val all = items(context)
        val kept = JSONArray()
        for (i in 0 until all.length()) {
            val item = all.optJSONObject(i) ?: continue
            if (item.optString("key") !in keys) kept.put(item)
        }
        prefs(context).edit().putString(KEY_ITEMS, kept.toString()).apply()
    }
}

/** Слушает уведомления телефона, когда человек дал на это доступ. */
class BankNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(notice: StatusBarNotification) {
        if (notice.packageName == packageName) return
        val notification = notice.notification
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString() ?: ""
        if (text.isBlank()) return
        val app = try {
            packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(notice.packageName, 0)
            ).toString()
        } catch (e: Exception) {
            notice.packageName
        }
        // Одно и то же уведомление банк обновляет: ключ — с текстом.
        BankNotices.keep(applicationContext, "${notice.key}:${text.hashCode()}", app,
            title, text, notice.postTime)
    }
}
