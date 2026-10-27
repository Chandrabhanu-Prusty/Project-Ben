package com.example.ben.overlay

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import com.example.ben.MainActivity
import kotlin.math.abs

class BenOverlayService : Service() {

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

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        initFloatingView()
        isRunning = true
    }

    private fun initFloatingView() {
        val sizeInPx = (56 * resources.displayMetrics.density).toInt()

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
            x = 100
            y = 300
            alpha = 0.9f
        }

        floatingView = BenFloatingView(this)

        setupDragAndClickListener()

        try {
            windowManager?.addView(floatingView, layoutParams)
        } catch (e: Exception) {
            // Permission might have been revoked
        }
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

                        // Clamping to screen display boundaries so the icon cannot be dragged off-screen
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

                        // If user tapped without dragging, open Ben
                        if (totalDx < CLICK_THRESHOLD && totalDy < CLICK_THRESHOLD) {
                            openBenApp()
                        }
                        return true
                    }
                }
                return false
            }
        })
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
        if (floatingView != null) {
            try {
                windowManager?.removeView(floatingView)
            } catch (e: Exception) {}
            floatingView = null
        }
        isRunning = false
    }
}
