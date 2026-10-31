package com.example.ben.notification

import android.app.Notification
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import java.util.Collections

class BenNotificationListenerService : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        var isConnected: Boolean = false
        var instance: BenNotificationListenerService? = null
        val activeNotificationsCache: MutableList<Map<String, Any?>> =
            Collections.synchronizedList(mutableListOf())

        fun getActiveNotificationsList(): List<Map<String, Any?>> {
            instance?.refreshActiveCache()
            return ArrayList(activeNotificationsCache)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
        instance = this
        refreshActiveCache()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
        if (instance == this) {
            instance = null
        }
    }

    fun refreshActiveCache() {
        try {
            val activeNotifs = activeNotifications ?: return
            val pm = packageManager
            val tempList = mutableListOf<Map<String, Any?>>()

            for (sbn in activeNotifs) {
                if (sbn.packageName == packageName) continue

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

                var body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                    ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

                // Extract multi-line inbox styles (common in Gmail, Outlook)
                val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                if (textLines != null && textLines.isNotEmpty()) {
                    val linesStr = textLines.filterNotNull().joinToString("\n") { it.toString() }
                    body = if (!body.isNullOrEmpty()) "$body\n$linesStr" else linesStr
                }

                val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
                if (!subText.isNullOrEmpty()) {
                    body = if (!body.isNullOrEmpty()) "$body ($subText)" else subText
                }

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

                tempList.add(payload)
            }

            activeNotificationsCache.clear()
            activeNotificationsCache.addAll(tempList)
        } catch (e: Exception) {
            // Ignore
        }
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

            var body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

            // Decode multi-line email notifications (Gmail, Outlook InboxStyle)
            val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            if (textLines != null && textLines.isNotEmpty()) {
                val linesStr = textLines.filterNotNull().joinToString("\n") { it.toString() }
                body = if (!body.isNullOrEmpty()) "$body\n$linesStr" else linesStr
            }

            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
            if (!subText.isNullOrEmpty()) {
                body = if (!body.isNullOrEmpty()) "$body ($subText)" else subText
            }

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

            // Update cache
            activeNotificationsCache.removeAll { it["source_key"] == sbn.key }
            activeNotificationsCache.add(0, payload)

            eventSink?.success(payload)
        } catch (e: Exception) {
            // Safe fallback
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        if (sbn == null) return

        try {
            activeNotificationsCache.removeAll { it["source_key"] == sbn.key }

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
