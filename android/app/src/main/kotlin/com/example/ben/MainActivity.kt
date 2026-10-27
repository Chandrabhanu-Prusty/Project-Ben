package com.example.ben

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.example.ben.notification.BenNotificationListenerService
import com.example.ben.overlay.BenOverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val NOTIFICATION_CHANNEL = "com.example.ben/notifications"
    private val NOTIFICATION_STREAM_CHANNEL = "com.example.ben/notification_stream"
    private val OVERLAY_CHANNEL = "com.example.ben/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Notification Management Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    val isGranted = NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
                    result.success(isGranted)
                }

                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // 2. Notification Live Event Stream Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BenNotificationListenerService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    BenNotificationListenerService.eventSink = null
                }
            }
        )

        // 3. Floating Overlay Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayPermissionGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "showOverlay" -> {
                    val intent = Intent(this, BenOverlayService::class.java).apply {
                        action = BenOverlayService.ACTION_SHOW
                    }
                    startService(intent)
                    result.success(true)
                }

                "hideOverlay" -> {
                    val intent = Intent(this, BenOverlayService::class.java).apply {
                        action = BenOverlayService.ACTION_HIDE
                    }
                    startService(intent)
                    result.success(true)
                }

                "setOpacity" -> {
                    val opacity = call.argument<Double>("opacity")?.toFloat() ?: 0.9f
                    val intent = Intent(this, BenOverlayService::class.java).apply {
                        action = BenOverlayService.ACTION_SET_OPACITY
                        putExtra(BenOverlayService.EXTRA_OPACITY, opacity)
                    }
                    startService(intent)
                    result.success(true)
                }

                "setSpeakingState" -> {
                    val isSpeaking = call.argument<Boolean>("isSpeaking") ?: false
                    val intent = Intent(this, BenOverlayService::class.java).apply {
                        action = BenOverlayService.ACTION_SET_SPEAKING
                        putExtra(BenOverlayService.EXTRA_IS_SPEAKING, isSpeaking)
                    }
                    startService(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
