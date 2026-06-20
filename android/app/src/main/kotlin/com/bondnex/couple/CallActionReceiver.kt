package com.bondnex.couple

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "ACTION_ANSWER" -> {
                CallManager.answer()
                NotificationHelper.dismissIncomingCallNotification(context)
                // Optionally start MainActivity so the user can see the call UI
                val activityIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                context.startActivity(activityIntent)
            }
            "ACTION_DECLINE" -> {
                CallManager.reject()
                NotificationHelper.dismissIncomingCallNotification(context)
            }
            "android.telecom.action.SHOW_MISSED_CALLS_NOTIFICATION" -> {
                // The system asks the default dialer to show a missed call notification.
                // We handle it here to prevent the default system dialer from showing its own notification.
                // You can optionally show a custom BondNex missed call notification here if needed.
            }
        }
    }
}
