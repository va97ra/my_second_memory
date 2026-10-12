package com.va97ra.ezhednevnikv2

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Распознавание речи телефона (Google) для просьбы Джарвису: оно точнее
 * своего офлайнового — лучше слышит имена, улицы и адреса.
 *
 * Имя «Джарвис» ждёт офлайновое распознавание телефона, если оно есть
 * (Android 12+): поднимается за доли секунды, а своя модель грузится секунды —
 * и всё это время имени не слышно. Только на телефоне, без сети: ожидание
 * имени никуда не отправляется. Сессии идут по кругу, пока их не остановят.
 *
 * Звук обеим даёт сам Ежедневник ([MicFeed]): когда микрофон включает
 * служба, она пищит на каждом включении и выключении.
 *
 * Канал ezhednevnik_v2/speech (jarvis_system_speech.dart): available,
 * listen(patience) → текст, пустая строка (промолчали) или null (системное
 * распознавание сейчас недоступно — без сети, занято, нет языка: тогда
 * Ежедневник слушает своим); stop, cancel; wakeAvailable, startWake,
 * stopWake; приложению — partial, wakePartial, wakePhrase, wakeFailed.
 */
object SystemSpeech {
    /** Сколько ждать начала речи, если приложение не сказало. */
    private const val DEFAULT_PATIENCE_MS = 6000L

    /**
     * Пауза после законченного куска: молчат дольше — просьба сказана
     * целиком. Просьбу закрывала первая же пауза, и договорить длинное
     * было нельзя.
     */
    private const val PAUSE_MS = 1300L

    private var recognizer: SpeechRecognizer? = null
    private var pending: MethodChannel.Result? = null
    private var channel: MethodChannel? = null

    private var waker: SpeechRecognizer? = null
    private var waking = false
    private val handler = Handler(Looper.getMainLooper())
    private val mic = MicFeed()
    private lateinit var app: Context

    private val restart = Runnable { startWake() }

    /** Сколько ждать речи в текущей просьбе. */
    private var patienceMs = DEFAULT_PATIENCE_MS

    /**
     * Своим звуком служба не отсчитывает тишину до начала речи — её
     * отсчитываем здесь: промолчали — звук кончается, и просьба тоже.
     */
    private val silence = Runnable {
        recognizer?.stopListening()
        mic.endSession()
        handler.postDelayed(giveUp, 1500)
    }

    /** Служба не ответила и на конец звука — просьба кончается тем, что успели сказать. */
    private val giveUp = Runnable {
        recognizer?.cancel()
        finish(spoken())
    }

    /** Сказанное в этой просьбе — кусками, по паузам. */
    private val said = StringBuilder()

    /** После куска помолчали — просьба сказана. */
    private val done = Runnable {
        finish(spoken())
        recognizer?.cancel()
    }

    private fun spoken(tail: String = "") =
        listOf(said.toString(), tail).filter { it.isNotBlank() }.joinToString(" ").trim()

    fun register(context: Context, messenger: BinaryMessenger) {
        app = context.applicationContext
        val speech = MethodChannel(messenger, "ezhednevnik_v2/speech")
        channel = speech
        speech.setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeAvailable" -> result.success(
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        SpeechRecognizer.isOnDeviceRecognitionAvailable(app)
                )
                "startWake" -> {
                    waking = true
                    startWake()
                    result.success(true)
                }
                "stopWake" -> {
                    waking = false
                    handler.removeCallbacks(restart)
                    waker?.cancel()
                    releaseMicIfIdle()
                    result.success(null)
                }
                "available" -> result.success(SpeechRecognizer.isRecognitionAvailable(context))
                "listen" -> listen(
                    context,
                    call.argument<Number>("patience")?.toLong() ?: DEFAULT_PATIENCE_MS,
                    result,
                )
                "stop" -> {
                    handler.removeCallbacks(silence)
                    silence.run()
                    result.success(null)
                }
                "cancel" -> {
                    recognizer?.cancel()
                    finish("")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun listen(context: Context, patience: Long, result: MethodChannel.Result) {
        finish("")
        pending = result
        patienceMs = patience
        said.clear()
        val engine = recognizer ?: SpeechRecognizer.createSpeechRecognizer(context).also {
            it.setRecognitionListener(listener)
            recognizer = it
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ru-RU")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            // Задумался посреди фразы — не обрывать: «завтра… в два… к врачу».
            // Целым числом: служба читает getIntExtra, а Long молча
            // превращала в 0 — паузу решала она сама.
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000)
        }
        start(engine, intent) { finish(null) }
        // Запуск не удался — просьба уже закончена, тишину отсчитывать незачем.
        if (pending === result) handler.postDelayed(silence, patienceMs)
    }

    private fun wakeIntent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ru-RU")
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
    }

    private fun startWake() {
        if (!waking || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val engine = waker ?: SpeechRecognizer.createOnDeviceSpeechRecognizer(app).also {
            it.setRecognitionListener(wakeListener)
            waker = it
        }
        start(engine, wakeIntent()) { failWake() }
    }

    /**
     * Запустить сессию со звуком Ежедневника.
     *
     * Своим звуком служба слушает, пока звук не кончится, и без кусков
     * отдаёт сказанное только в самом конце — Джарвис ждал без конца. По
     * кускам каждая законченная фраза приходит сразу (`onSegmentResults`).
     */
    private fun start(engine: SpeechRecognizer, intent: Intent, failed: () -> Unit) {
        if (mic.feed(intent) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
        }
        try {
            engine.startListening(intent)
        } catch (e: Exception) {
            failed()
        }
    }

    private fun restartWake(delayMs: Long) {
        if (!waking) return
        handler.removeCallbacks(restart)
        handler.postDelayed(restart, delayMs)
    }

    /** Офлайновое распознавание не может — Ежедневник ждёт имя своим. */
    private fun failWake() {
        waking = false
        handler.removeCallbacks(restart)
        releaseMicIfIdle()
        channel?.invokeMethod("wakeFailed", null)
    }

    /** Никто не слушает — микрофон выключается. */
    private fun releaseMicIfIdle() {
        if (!waking && pending == null) mic.release()
    }

    private val wakeListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}
        override fun onEvent(eventType: Int, params: Bundle?) {}

        override fun onPartialResults(partialResults: Bundle?) {
            val text = first(partialResults)
            if (waking && text.isNotEmpty()) channel?.invokeMethod("wakePartial", text)
        }

        override fun onResults(results: Bundle?) {
            heard(results)
            restartWake(50)
        }

        /** Одна долгая сессия: каждая фраза — сразу, без перезапуска. */
        override fun onSegmentResults(segmentResults: Bundle) = heard(segmentResults)

        override fun onEndOfSegmentedSession() = restartWake(50)

        private fun heard(results: Bundle?) {
            val text = first(results)
            if (waking && text.isNotEmpty()) channel?.invokeMethod("wakePhrase", text)
        }

        override fun onError(error: Int) {
            if (!waking) return
            when (error) {
                SpeechRecognizer.ERROR_NO_MATCH,
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> restartWake(50)
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
                SpeechRecognizer.ERROR_CLIENT -> restartWake(500)
                else -> failWake()
            }
        }
    }

    private fun finish(text: String?) {
        handler.removeCallbacks(silence)
        handler.removeCallbacks(giveUp)
        handler.removeCallbacks(done)
        val result = pending ?: return
        pending = null
        mic.endSession()
        releaseMicIfIdle()
        result.success(text)
    }

    private fun first(bundle: Bundle?): String =
        bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: ""

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {
            handler.removeCallbacks(silence)
            handler.removeCallbacks(done)
        }

        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEvent(eventType: Int, params: Bundle?) {}

        /** Замолчали, а фразы нет (шум) — снова ждём речи, не дольше терпения. */
        override fun onEndOfSpeech() {
            if (pending == null) return
            handler.removeCallbacks(silence)
            handler.postDelayed(silence, patienceMs)
        }

        /** Кусок сказан — ждём паузу: заговорят снова, дослушаем. */
        override fun onSegmentResults(segmentResults: Bundle) {
            val text = first(segmentResults)
            if (text.isEmpty() || pending == null) return
            if (said.isNotEmpty()) said.append(' ')
            said.append(text)
            channel?.invokeMethod("partial", spoken())
            handler.removeCallbacks(done)
            handler.postDelayed(done, PAUSE_MS)
        }

        override fun onEndOfSegmentedSession() = finish(spoken())

        override fun onPartialResults(partialResults: Bundle?) {
            val text = first(partialResults)
            if (text.isEmpty()) return
            handler.removeCallbacks(silence)
            handler.removeCallbacks(done)
            channel?.invokeMethod("partial", spoken(text))
        }

        override fun onResults(results: Bundle?) = finish(spoken(first(results)))

        override fun onError(error: Int) = finish(
            when {
                said.isNotEmpty() -> spoken()
                // Промолчали или ничего не разобрали — это ответ, а не поломка.
                error == SpeechRecognizer.ERROR_NO_MATCH ||
                    error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> ""
                // Нет сети, сервис занят или без русского — слушает своё.
                else -> null
            }
        )
    }
}
