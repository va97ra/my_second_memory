package com.va97ra.ezhednevnikv2

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.net.Uri
import android.provider.AlarmClock
import android.provider.ContactsContract
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Руки Джарвиса в телефоне. Канал ezhednevnik_v2/phone (jarvis_phone.dart).
 *
 * Звонки и сообщения не уходят сами: открывается набор номера или чат с
 * готовым текстом, нажимает человек. Контакты читаются только по просьбе
 * позвонить или написать и только с разрешения. Перенесено из MemoryVoice.
 */
class PhoneActions(
    private val activity: Activity,
    /** Спросить разрешение; ответ — в колбэк. */
    private val ask: (String, (Boolean) -> Unit) -> Unit,
) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "ezhednevnik_v2/phone").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "setAlarm" -> result.success(start(Intent(AlarmClock.ACTION_SET_ALARM).apply {
                        putExtra(AlarmClock.EXTRA_HOUR, call.argument<Int>("hour") ?: 7)
                        putExtra(AlarmClock.EXTRA_MINUTES, call.argument<Int>("minute") ?: 0)
                        putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                    }))
                    "setTimer" -> result.success(start(Intent(AlarmClock.ACTION_SET_TIMER).apply {
                        putExtra(AlarmClock.EXTRA_LENGTH, call.argument<Int>("seconds") ?: 60)
                        putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                    }))
                    "torch" -> result.success(torch(call.argument<Boolean>("on") ?: true))
                    "openApp" -> result.success(openApp(call.argument<String>("query") ?: ""))
                    // Есть разрешение на звонки — Джарвис звонит сам; нет —
                    // открывает набор, «Вызов» нажимает человек.
                    "call" -> withPermission(Manifest.permission.CALL_PHONE) { allowed ->
                        val number = Uri.fromParts("tel", call.argument<String>("number") ?: "", null)
                        result.success(when {
                            allowed && start(Intent(Intent.ACTION_CALL, number)) -> "call"
                            start(Intent(Intent.ACTION_DIAL, number)) -> "dial"
                            else -> null
                        })
                    }
                    "message" -> result.success(message(
                        call.argument<String>("number") ?: "",
                        call.argument<String>("text") ?: "",
                        call.argument<String>("app") ?: "sms",
                    ))
                    "route" -> result.success(route(call.argument<String>("to") ?: ""))
                    "contacts" -> withPermission(Manifest.permission.READ_CONTACTS) { allowed ->
                        result.success(if (allowed) contacts() else null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("phone", e.message, null)
            }
        }
    }

    private fun start(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: SecurityException) {
        // Звонок без разрешения — тогда открывается набор.
        false
    }

    private fun torch(on: Boolean): Boolean {
        val manager = activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val id = manager.cameraIdList.firstOrNull {
            manager.getCameraCharacteristics(it)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        } ?: return false
        manager.setTorchMode(id, on)
        return true
    }

    /** Разговорные названия → части названий приложений или пакетов. */
    private val aliases = mapOf(
        "камер" to listOf("camera", "камера"),
        "карт" to listOf("yandexmaps", "maps", "карты"),
        "навигатор" to listOf("yandexnavi", "navigator", "навигатор"),
        "телеграм" to listOf("telegram"),
        "ватсап" to listOf("whatsapp"),
        "вотсап" to listOf("whatsapp"),
        "вконтакт" to listOf("vkontakte", "вконтакте", "com.vk"),
        "ютуб" to listOf("youtube"),
        "галере" to listOf("gallery", "галерея", "фото", "photos"),
        "фото" to listOf("photos", "gallery", "фото"),
        "браузер" to listOf("chrome", "browser", "браузер"),
        "музык" to listOf("music", "музыка"),
        "почт" to listOf("mail", "почта", "gmail"),
        "сбер" to listOf("sberbank", "сбер"),
        "такси" to listOf("taxi", "такси"),
        "часы" to listOf("deskclock", "clock", "часы"),
    )

    /** Открыть приложение по названию. Возвращает его название или null. */
    private fun openApp(query: String): String? {
        val said = query.lowercase().replace('ё', 'е').trim()
        if (said.isEmpty()) return null
        if (said.startsWith("камер") &&
            start(Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA))) return "Камера"
        val packages = activity.packageManager
        val launchers = packages.queryIntentActivities(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0
        )
        val keys = aliases.entries.filter { said.contains(it.key) }.flatMap { it.value } +
            said.split(" ").filter { it.length >= 3 }
        val match = launchers.firstOrNull { info ->
            val label = info.loadLabel(packages).toString().lowercase().replace('ё', 'е')
            val name = info.activityInfo.packageName.lowercase()
            label == said || keys.any { label.contains(it) || name.contains(it) }
        } ?: return null
        val intent = packages.getLaunchIntentForPackage(match.activityInfo.packageName)
            ?: return null
        activity.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return match.loadLabel(packages).toString()
    }

    /**
     * Куда ехать — в картах телефона: «Яндекс Карты» покажут место с кнопкой
     * «Маршрут», Google Maps сразу строят путь оттуда, где вы сейчас. Карты
     * знают пробки и транспорт лучше, чем любой разбор фраз. Возвращает, в
     * каких картах открыто, или null — карт нет.
     */
    private fun route(to: String): String? {
        if (to.isBlank()) return null
        val place = Uri.encode(to)
        if (start(Intent(Intent.ACTION_VIEW, Uri.parse("yandexmaps://maps.yandex.ru/?text=$place"))
                .setPackage("ru.yandex.yandexmaps"))) return "Яндекс Картах"
        if (start(Intent(Intent.ACTION_VIEW,
                Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$place"))
                .setPackage("com.google.android.apps.maps"))) return "Google Картах"
        if (start(Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=$place")))) return "картах"
        return null
    }

    /** Чат с готовым текстом: WhatsApp по номеру, Telegram — выбрать чат, иначе SMS. */
    private fun message(number: String, text: String, app: String): Boolean = when (app) {
        "whatsapp" -> start(Intent(Intent.ACTION_VIEW, Uri.parse(
            "https://wa.me/${number.filter { it.isDigit() }}?text=${Uri.encode(text)}"
        )).setPackage("com.whatsapp"))
        "telegram" -> start(Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            setPackage("org.telegram.messenger")
        })
        else -> start(Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", number, null))
            .putExtra("sms_body", text))
    }

    private fun withPermission(name: String, then: (Boolean) -> Unit) {
        if (activity.checkSelfPermission(name) == PackageManager.PERMISSION_GRANTED) {
            then(true)
        } else {
            ask(name, then)
        }
    }

    /** Имена и основные номера контактов — для поиска «маме» → «Мама». */
    private fun contacts(): List<Map<String, String>> {
        val found = linkedMapOf<String, String>()
        activity.contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.IS_PRIMARY,
            ),
            null, null, null,
        )?.use { rows ->
            while (rows.moveToNext()) {
                val name = rows.getString(0) ?: continue
                val number = rows.getString(1) ?: continue
                if (name !in found || rows.getInt(2) == 1) found[name] = number
            }
        }
        return found.map { (name, number) -> mapOf("name" to name, "number" to number) }
    }
}
