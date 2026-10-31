package com.example.ben.overlay

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.view.View
import com.example.ben.R
import kotlin.math.min

class BenFloatingView(context: Context) : View(context) {

    private var omnitrixBitmap: Bitmap? = null

    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#39FF67")
        style = Paint.Style.STROKE
        strokeWidth = 6f
    }

    private val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#8039FF67")
        style = Paint.Style.STROKE
        strokeWidth = 10f
    }

    private val fallbackBgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#39FF67")
        style = Paint.Style.FILL
    }

    private val fallbackWedgePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#101512")
        style = Paint.Style.FILL
    }

    private val clipPath = Path()
    private val srcRect = Rect()
    private val destRectF = RectF()

    var isSpeaking: Boolean = false
        set(value) {
            field = value
            invalidate()
        }

    init {
        try {
            omnitrixBitmap = BitmapFactory.decodeResource(resources, R.drawable.omnitrix_floating)
        } catch (e: Exception) {
            omnitrixBitmap = null
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val cx = width / 2f
        val cy = height / 2f
        val radius = (min(width, height) / 2f) - 6f

        clipPath.reset()
        clipPath.addCircle(cx, cy, radius, Path.Direction.CW)

        val bitmap = omnitrixBitmap
        if (bitmap != null) {
            canvas.save()
            canvas.clipPath(clipPath)
            srcRect.set(0, 0, bitmap.width, bitmap.height)
            destRectF.set(cx - radius, cy - radius, cx + radius, cy + radius)
            canvas.drawBitmap(bitmap, srcRect, destRectF, null)
            canvas.restore()
        } else {
            // Authentic Omnitrix hourglass vector fallback
            canvas.drawCircle(cx, cy, radius, fallbackBgPaint)

            val leftWedge = Path().apply {
                moveTo(cx - radius, cy - radius * 0.7f)
                lineTo(cx - radius * 0.15f, cy)
                lineTo(cx - radius, cy + radius * 0.7f)
                close()
            }
            val rightWedge = Path().apply {
                moveTo(cx + radius, cy - radius * 0.7f)
                lineTo(cx + radius * 0.15f, cy)
                lineTo(cx + radius, cy + radius * 0.7f)
                close()
            }
            canvas.drawPath(leftWedge, fallbackWedgePaint)
            canvas.drawPath(rightWedge, fallbackWedgePaint)
        }

        // Draw glowing outer border ring
        if (isSpeaking) {
            glowPaint.color = Color.parseColor("#B339FF67")
            canvas.drawCircle(cx, cy, radius + 2f, glowPaint)
            borderPaint.color = Color.parseColor("#A5FFB6")
            borderPaint.strokeWidth = 7f
        } else {
            borderPaint.color = Color.parseColor("#39FF67")
            borderPaint.strokeWidth = 5f
        }
        canvas.drawCircle(cx, cy, radius, borderPaint)
    }
}
