package com.example.ben.overlay

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View

class BenFloatingView(context: Context) : View(context) {

    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#050706") // Deep Black
        style = Paint.Style.FILL
    }

    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#39FF67") // Neon Green
        style = Paint.Style.STROKE
        strokeWidth = 6f
    }

    private val centerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#39FF67") // Neon Green
        style = Paint.Style.FILL
    }

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#050706")
        textSize = 28f
        isFakeBoldText = true
        textAlign = Paint.Align.CENTER
    }

    var isSpeaking: Boolean = false
        set(value) {
            field = value
            invalidate()
        }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val cx = width / 2f
        val cy = height / 2f
        val radius = (Math.min(width, height) / 2f) - 6f

        // 1. Draw circular background
        canvas.drawCircle(cx, cy, radius, bgPaint)

        // 2. Draw outer Neon Green Omnitrix border
        borderPaint.color = if (isSpeaking) Color.parseColor("#A5FFB6") else Color.parseColor("#39FF67")
        borderPaint.strokeWidth = if (isSpeaking) 8f else 5f
        canvas.drawCircle(cx, cy, radius, borderPaint)

        // 3. Draw inner center circle
        val centerRadius = radius * 0.48f
        canvas.drawCircle(cx, cy, centerRadius, centerPaint)

        // 4. Draw Ben "10" text
        val textY = cy - ((textPaint.descent() + textPaint.ascent()) / 2)
        canvas.drawText("10", cx, textY, textPaint)
    }
}
