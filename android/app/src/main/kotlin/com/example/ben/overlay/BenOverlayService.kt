package com.example.ben.overlay

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.example.ben.MainActivity
import com.example.ben.notification.BenNotificationListenerService
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.concurrent.thread
import kotlin.math.abs

class BenOverlayService : Service(), TextToSpeech.OnInitListener {

    companion object {
        const val ACTION_SHOW = "com.example.ben.SHOW_OVERLAY"
        const val ACTION_HIDE = "com.example.ben.HIDE_OVERLAY"
        const val ACTION_SET_OPACITY = "com.example.ben.SET_OPACITY"
        const val ACTION_SET_SPEAKING = "com.example.ben.SET_SPEAKING"

        const val EXTRA_OPACITY = "extra_opacity"
        const val EXTRA_IS_SPEAKING = "extra_is_speaking"

        var isRunning: Boolean = false
    }

    private var windowManager: WindowManager? = null
    private var floatingView: BenFloatingView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    // Expanded Assistant Floating Dialog
    private var assistantCardView: LinearLayout? = null
    private var assistantLayoutParams: WindowManager.LayoutParams? = null
    private var statusTextView: TextView? = null
    private var responseTextView: TextView? = null
    private var micButton: Button? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isListening = false
    private var userHonorific = "Master"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        textToSpeech = TextToSpeech(this, this)
        initFloatingBubble()
        initAssistantCard()
        isRunning = true
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.language = Locale.US
            // Deep, masculine resonance
            textToSpeech?.setPitch(0.85f)
            textToSpeech?.setSpeechRate(0.95f)

            try {
                val voices = textToSpeech?.voices
                if (voices != null) {
                    for (v in voices) {
                        val name = v.name.lowercase(Locale.US)
                        if (v.locale == Locale.US && (name.contains("male") || name.contains("en-us-x-sfg") || name.contains("en-us-x-tpd") || name.contains("en-us-x-iol"))) {
                            textToSpeech?.voice = v
                            break
                        }
                    }
                }
            } catch (e: Exception) {}
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        ).toInt()
    }

    private fun initFloatingBubble() {
        val sizeInPx = dpToPx(56f)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        layoutParams = WindowManager.LayoutParams(
            sizeInPx,
            sizeInPx,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 80
            y = 350
            alpha = 0.9f
        }

        floatingView = BenFloatingView(this)
        setupDragAndClickListener()

        try {
            windowManager?.addView(floatingView, layoutParams)
        } catch (e: Exception) {}
    }

    private fun setupDragAndClickListener() {
        floatingView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private val CLICK_THRESHOLD = 15f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                if (event == null || layoutParams == null) return false

                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = layoutParams!!.x
                        initialY = layoutParams!!.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY

                        val dm = resources.displayMetrics
                        val maxX = dm.widthPixels - (floatingView?.width ?: 0)
                        val maxY = dm.heightPixels - (floatingView?.height ?: 0)

                        val newX = (initialX + dx.toInt()).coerceIn(0, maxX)
                        val newY = (initialY + dy.toInt()).coerceIn(0, maxY)

                        layoutParams!!.x = newX
                        layoutParams!!.y = newY
                        windowManager?.updateViewLayout(floatingView, layoutParams)
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        val totalDx = abs(event.rawX - initialTouchX)
                        val totalDy = abs(event.rawY - initialTouchY)

                        // If user tapped without dragging, activate Voice Assistant directly!
                        if (totalDx < CLICK_THRESHOLD && totalDy < CLICK_THRESHOLD) {
                            toggleVoiceAssistantCard()
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun initAssistantCard() {
        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val cardWidth = dpToPx(330f)

        assistantLayoutParams = WindowManager.LayoutParams(
            cardWidth,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = dpToPx(70f)
        }

        assistantCardView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16f), dpToPx(14f), dpToPx(16f), dpToPx(14f))

            background = GradientDrawable().apply {
                setColor(Color.parseColor("#090E0B")) // Deep Black-Green
                cornerRadius = dpToPx(20f).toFloat()
                setStroke(dpToPx(2f), Color.parseColor("#39FF67")) // Neon Green Omnitrix border
            }

            elevation = dpToPx(12f).toFloat()
            visibility = View.GONE
        }

        // Header Row
        val headerLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val titleView = TextView(this).apply {
            text = "BEN ASSISTANT"
            setTextColor(Color.parseColor("#39FF67"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        val openAppButton = TextView(this).apply {
            text = "App ↗"
            setTextColor(Color.parseColor("#80A68A"))
            textSize = 12f
            setPadding(dpToPx(8f), dpToPx(4f), dpToPx(8f), dpToPx(4f))
            setOnClickListener {
                hideAssistantCard()
                openBenApp()
            }
        }

        val closeButton = TextView(this).apply {
            text = "✕"
            setTextColor(Color.parseColor("#FFFFFF"))
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dpToPx(8f), dpToPx(4f), dpToPx(4f), dpToPx(4f))
            setOnClickListener {
                hideAssistantCard()
            }
        }

        headerLayout.addView(titleView)
        headerLayout.addView(openAppButton)
        headerLayout.addView(closeButton)
        assistantCardView?.addView(headerLayout)

        // Status view
        statusTextView = TextView(this).apply {
            text = "Ready to listen"
            setTextColor(Color.parseColor("#FFFFFF"))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dpToPx(10f), 0, dpToPx(4f))
        }
        assistantCardView?.addView(statusTextView)

        // Response / Answer text view
        responseTextView = TextView(this).apply {
            text = "Tap the mic and ask me anything, or request notification & email updates."
            setTextColor(Color.parseColor("#B5D0BD"))
            textSize = 13f
            setPadding(0, dpToPx(4f), 0, dpToPx(12f))
        }
        assistantCardView?.addView(responseTextView)

        // Mic Button & Action Row
        val actionRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        micButton = Button(this).apply {
            text = "🎤 Tap to Speak"
            setTextColor(Color.parseColor("#050706"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#39FF67"))
                cornerRadius = dpToPx(16f).toFloat()
            }
            setPadding(dpToPx(20f), dpToPx(8f), dpToPx(20f), dpToPx(8f))
            setOnClickListener {
                if (isListening) {
                    stopSpeechRecognition()
                } else {
                    startSpeechRecognition()
                }
            }
        }

        actionRow.addView(micButton)
        assistantCardView?.addView(actionRow)

        try {
            windowManager?.addView(assistantCardView, assistantLayoutParams)
        } catch (e: Exception) {}
    }

    private fun toggleVoiceAssistantCard() {
        if (assistantCardView?.visibility == View.VISIBLE) {
            hideAssistantCard()
        } else {
            showAssistantCard()
        }
    }

    private fun showAssistantCard() {
        // Read user honorific from prefs
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        userHonorific = prefs.getString("flutter.user_honorific", "Master") ?: "Master"

        assistantCardView?.visibility = View.VISIBLE
        statusTextView?.text = "Listening to you, $userHonorific..."
        responseTextView?.text = "Speak now..."
        startSpeechRecognition()
    }

    private fun hideAssistantCard() {
        stopSpeechRecognition()
        textToSpeech?.stop()
        assistantCardView?.visibility = View.GONE
    }

    private fun startSpeechRecognition() {
        mainHandler.post {
            try {
                if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                    statusTextView?.text = "Speech recognizer not available"
                    return@post
                }

                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.US.toString())
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        isListening = true
                        micButton?.text = "⏹ Stop Listening"
                        micButton?.background = GradientDrawable().apply {
                            setColor(Color.parseColor("#FF4D4D"))
                            cornerRadius = dpToPx(16f).toFloat()
                        }
                        statusTextView?.text = "Listening, $userHonorific..."
                    }

                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {
                        isListening = false
                        micButton?.text = "🎤 Tap to Speak"
                        micButton?.background = GradientDrawable().apply {
                            setColor(Color.parseColor("#39FF67"))
                            cornerRadius = dpToPx(16f).toFloat()
                        }
                        statusTextView?.text = "Thinking, $userHonorific..."
                    }

                    override fun onError(error: Int) {
                        isListening = false
                        micButton?.text = "🎤 Tap to Speak"
                        micButton?.background = GradientDrawable().apply {
                            setColor(Color.parseColor("#39FF67"))
                            cornerRadius = dpToPx(16f).toFloat()
                        }
                        statusTextView?.text = "Could not hear clearly"
                        responseTextView?.text = "Please tap the mic and try speaking again, $userHonorific."
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        if (!matches.isNullOrEmpty()) {
                            val userQuery = matches[0]
                            statusTextView?.text = "\"$userQuery\""
                            responseTextView?.text = "Analyzing..."
                            queryGroqAi(userQuery)
                        }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                speechRecognizer?.startListening(intent)
            } catch (e: Exception) {
                statusTextView?.text = "Error starting voice recognition"
            }
        }
    }

    private fun stopSpeechRecognition() {
        isListening = false
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
            speechRecognizer = null
        } catch (e: Exception) {}

        micButton?.text = "🎤 Tap to Speak"
        micButton?.background = GradientDrawable().apply {
            setColor(Color.parseColor("#39FF67"))
            cornerRadius = dpToPx(16f).toFloat()
        }
    }

    private fun queryGroqAi(userQuery: String) {
        thread {
            try {
                val notifications = BenNotificationListenerService.getActiveNotificationsList()
                val notifArray = JSONArray()

                for (n in notifications) {
                    val obj = JSONObject()
                    obj.put("app_name", n["app_name"])
                    obj.put("sender_name", n["sender_name"])
                    obj.put("title", n["title"])
                    obj.put("body", n["body"])
                    obj.put("received_at", n["timestamp"])
                    notifArray.put(obj)
                }

                val nowFormat = SimpleDateFormat("h:mm a, EEEE, MMMM d, yyyy", Locale.US)
                val currentDeviceTime = nowFormat.format(Date())

                val prompt = """
You are Ben, a personal, loyal, Siri/JARVIS-level AI assistant.
Current local device time: $currentDeviceTime.
User's preferred title: $userHonorific.

Address the user with phrases like "Right away, $userHonorific", "Certainly, $userHonorific", "As you requested, $userHonorific".

Capabilities:
1. General Assistant: Answer ANY query (current time, date, math, questions, advice, greetings).
2. Notifications & Emails: Look at the notifications below (especially Gmail, Outlook, Messages). If the user asks about emails or what they missed, give them a crisp summary.

Notifications:
$notifArray

User query:
$userQuery

Return valid JSON:
{
  "summary": "Conversational, spoken-friendly answer addressing user as $userHonorific"
}
"""

                val groqKey = "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"
                val url = URL("https://api.groq.com/openai/v1/chat/completions")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Bearer $groqKey")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true
                conn.connectTimeout = 8000
                conn.readTimeout = 10000

                val rootReq = JSONObject()
                rootReq.put("model", "openai/gpt-oss-20b")
                val msgs = JSONArray()
                val sysMsg = JSONObject().apply {
                    put("role", "system")
                    put("content", "You are Ben, personal AI assistant. Always address user as $userHonorific and return JSON.")
                }
                val usrMsg = JSONObject().apply {
                    put("role", "user")
                    put("content", prompt)
                }
                msgs.put(sysMsg)
                msgs.put(usrMsg)
                rootReq.put("messages", msgs)
                rootReq.put("response_format", JSONObject().apply { put("type", "json_object") })
                rootReq.put("temperature", 0.3)

                conn.outputStream.use { os ->
                    os.write(rootReq.toString().toByteArray())
                }

                var responseText = ""
                if (conn.responseCode == 200) {
                    val respStr = conn.inputStream.bufferedReader().use { it.readText() }
                    val jsonResp = JSONObject(respStr)
                    val choices = jsonResp.optJSONArray("choices")
                    if (choices != null && choices.length() > 0) {
                        val contentStr = choices.getJSONObject(0).getJSONObject("message").getString("content")
                        val innerJson = JSONObject(contentStr)
                        responseText = innerJson.optString("summary", "")
                    }
                }

                if (responseText.isEmpty()) {
                    responseText = generateFallbackResponse(userQuery)
                }

                val finalAnswer = responseText
                mainHandler.post {
                    statusTextView?.text = "Ben Speaking..."
                    responseTextView?.text = finalAnswer

                    // Speak in deep masculine voice
                    textToSpeech?.speak(
                        finalAnswer,
                        TextToSpeech.QUEUE_FLUSH,
                        null,
                        "BEN_OVERLAY_TTS"
                    )

                    // Auto dismiss after 10 seconds of idle
                    mainHandler.postDelayed({
                        if (!isListening && assistantCardView?.visibility == View.VISIBLE) {
                            hideAssistantCard()
                        }
                    }, 10000)
                }
            } catch (e: Exception) {
                val fallback = generateFallbackResponse(userQuery)
                mainHandler.post {
                    statusTextView?.text = "Ben Speaking..."
                    responseTextView?.text = fallback
                    textToSpeech?.speak(fallback, TextToSpeech.QUEUE_FLUSH, null, "BEN_OVERLAY_TTS")
                }
            }
        }
    }

    private fun generateFallbackResponse(query: String): String {
        val q = query.lowercase(Locale.US)
        val nowFormat = SimpleDateFormat("h:mm a", Locale.US)
        val currentTime = nowFormat.format(Date())
        val dateFormat = SimpleDateFormat("EEEE, MMMM d", Locale.US)
        val currentDate = dateFormat.format(Date())

        if (q.contains("time") || q.contains("clock")) {
            return "It is currently $currentTime, $userHonorific."
        }
        if (q.contains("date") || q.contains("today")) {
            return "Today is $currentDate, $userHonorific."
        }
        if (q.contains("email") || q.contains("mail")) {
            val notifs = BenNotificationListenerService.getActiveNotificationsList()
            val emails = notifs.filter {
                val app = (it["app_name"] as? String)?.lowercase(Locale.US) ?: ""
                app.contains("mail") || app.contains("gmail") || app.contains("outlook")
            }
            return if (emails.isEmpty()) {
                "You do not have any new email notifications at the moment, $userHonorific."
            } else {
                "You have ${emails.size} email alerts, $userHonorific. Latest is from ${emails[0]["sender_name"] ?: "email"}: ${emails[0]["title"] ?: ""}."
            }
        }
        if (q.contains("hello") || q.contains("hi") || q.contains("who are you")) {
            return "Greetings, $userHonorific. I am Ben, your personal notification and voice assistant. How may I serve you?"
        }

        val notifs = BenNotificationListenerService.getActiveNotificationsList()
        return if (notifs.isEmpty()) {
            "You have no new notifications right now, $userHonorific. You're completely caught up!"
        } else {
            "You have ${notifs.size} active notifications on your device, $userHonorific."
        }
    }

    private fun openBenApp() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(launchIntent)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_HIDE -> {
                hideAssistantCard()
                stopSelf()
            }

            ACTION_SET_OPACITY -> {
                val opacity = intent.getFloatExtra(EXTRA_OPACITY, 0.9f)
                layoutParams?.alpha = opacity
                if (floatingView != null && layoutParams != null) {
                    windowManager?.updateViewLayout(floatingView, layoutParams)
                }
            }

            ACTION_SET_SPEAKING -> {
                val speaking = intent.getBooleanExtra(EXTRA_IS_SPEAKING, false)
                floatingView?.isSpeaking = speaking
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        hideAssistantCard()
        if (assistantCardView != null) {
            try {
                windowManager?.removeView(assistantCardView)
            } catch (e: Exception) {}
            assistantCardView = null
        }
        if (floatingView != null) {
            try {
                windowManager?.removeView(floatingView)
            } catch (e: Exception) {}
            floatingView = null
        }
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        speechRecognizer?.destroy()
        isRunning = false
    }
}
