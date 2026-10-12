package com.va97ra.ezhednevnikv2

import android.annotation.SuppressLint
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.ParcelFileDescriptor
import android.speech.RecognizerIntent
import android.system.ErrnoException
import android.system.Os
import android.system.OsConstants
import java.io.IOException
import java.io.OutputStream

/**
 * Микрофон Ежедневника для распознавания речи телефона.
 *
 * Службы распознавания Google пищат каждый раз, когда сами включают и
 * выключают микрофон, а ожидание имени перезапускается после каждой паузы —
 * телефон пищал без конца. Отключить писк они дают только приложениям Google:
 * `com.google.recognition.extra.MUTE_AUDIO_BEEPS` читается лишь под проверкой
 * `enableFirstPartyAppFeatures` (найдено в их коде 11 октября 2026). Звук,
 * который приложение отдаёт само (`EXTRA_AUDIO_SOURCE`, Android 13+), они
 * принимают от любого приложения и тогда не пищат: микрофон не их.
 *
 * Запись идёт без перерывов, пока Джарвис слушает; каждая сессия
 * распознавания получает свою трубу. Закрытая труба — конец звука для
 * сессии.
 */
class MicFeed {
    /** Читается и потоком записи: выключили — он видит это сразу. */
    @Volatile
    private var record: AudioRecord? = null

    @Volatile
    private var sink: OutputStream? = null

    /**
     * Свой конец трубы для чтения. Закрывается только с концом сессии:
     * распознавание, которое ещё подключается к службе, отправляет запуск
     * позже — закрытый раньше конец давал «Bad file descriptor», и просьба
     * падала.
     */
    private var source: ParcelFileDescriptor? = null

    /**
     * Отдать звук сессии, которую запустят с [intent]. false — отдать нечем
     * (старый Android, микрофон занят): служба слушает сама.
     */
    fun feed(intent: Intent): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        endSession()
        if (record == null && !startRecord()) return false
        val (read, write) = ParcelFileDescriptor.createPipe()
        source = read
        // Служба перестала читать — кусок пропадает, а запись не встаёт.
        // Кусок меньше PIPE_BUF (4 КБ) и уходит в трубу целиком или никак:
        // отсчёты звука не съезжают на полбайта.
        Os.fcntlInt(write.fileDescriptor, OsConstants.F_SETFL, OsConstants.O_NONBLOCK)
        sink = ParcelFileDescriptor.AutoCloseOutputStream(write)
        intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, read)
        intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
        intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
        intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, RATE)
        return true
    }

    /** Конец звука для текущей сессии: она доделывает то, что услышала. */
    fun endSession() {
        val out = sink
        sink = null
        val read = source
        source = null
        try {
            out?.close()
            read?.close()
        } catch (_: IOException) {
        }
    }

    /** Выключить микрофон совсем. */
    fun release() {
        endSession()
        val current = record ?: return
        record = null
        try {
            current.stop()
        } catch (_: IllegalStateException) {
        }
        current.release()
    }

    // Разрешение на микрофон у Ежедневника уже есть: без него Джарвис не
    // включается.
    @SuppressLint("MissingPermission")
    private fun startRecord(): Boolean {
        val min = AudioRecord.getMinBufferSize(RATE, CHANNEL, ENCODING)
        if (min <= 0) return false
        val created = try {
            AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                RATE,
                CHANNEL,
                ENCODING,
                maxOf(min, CHUNK * 4),
            )
        } catch (e: Exception) {
            return false
        }
        if (created.state != AudioRecord.STATE_INITIALIZED) {
            created.release()
            return false
        }
        try {
            created.startRecording()
        } catch (e: IllegalStateException) {
            created.release()
            return false
        }
        record = created
        Thread({ pump(created) }, "jarvis-mic").start()
        return true
    }

    /** Переливает звук из микрофона в трубу текущей сессии. */
    private fun pump(source: AudioRecord) {
        val buffer = ByteArray(CHUNK)
        while (record === source) {
            val read = source.read(buffer, 0, buffer.size)
            if (read < 0) break
            val out = sink ?: continue
            try {
                out.write(buffer, 0, read)
            } catch (e: IOException) {
                // Труба полна — служба не читает (сессия кончилась): кусок
                // пропадает. Другая ошибка — труба закрыта, ждём следующую.
                val full = (e.cause as? ErrnoException)?.errno == OsConstants.EAGAIN
                if (!full && sink === out) sink = null
            }
        }
    }

    private companion object {
        const val RATE = 16000
        const val CHANNEL = AudioFormat.CHANNEL_IN_MONO
        const val ENCODING = AudioFormat.ENCODING_PCM_16BIT

        /** 100 мс звука. */
        const val CHUNK = RATE / 10 * 2
    }
}
