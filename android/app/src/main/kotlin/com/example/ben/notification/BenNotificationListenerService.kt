package com.example.ben.notification

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class BenNotificationListenerService : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        var isConnected: Boolean = false
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        // Skip our own app's notifications to prevent feedback loops
        if (sbn.packageName == packageName) return

        try {
            val pm = packageManager
            val appInfo = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(sbn.packageName, android.content.pm.PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(sbn.packageName, 0)
                }
            } catch (e: Exception) {
                null
            }

            val appName = if (appInfo != null) pm.getApplicationLabel(appInfo).toString() else sbn.packageName

            val extras = sbn.notification.extras
            val title = extras.getString(Notification.EXTRA_TITLE)
                ?: extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

            val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

            val senderName = extras.getString(Notification.EXTRA_CONVERSATION_TITLE)
                ?: extras.getString(Notification.EXTRA_TITLE)

            val payload = HashMap<String, Any?>()
            payload["app_name"] = appName
            payload["package_name"] = sbn.packageName
            payload["source_key"] = sbn.key
            payload["sender_name"] = senderName
            payload["title"] = title
            payload["body"] = body
            payload["timestamp"] = sbn.postTime

            eventSink?.success(payload)
        } catch (e: Exception) {
            // Safe fallback: avoid crashing notification service
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        if (sbn == null) return

        try {
            val payload = HashMap<String, Any?>()
            payload["removed"] = true
            payload["source_key"] = sbn.key
            payload["timestamp"] = System.currentTimeMillis()

            eventSink?.success(payload)
        } catch (e: Exception) {
            // Ignore
        }
    }
}
