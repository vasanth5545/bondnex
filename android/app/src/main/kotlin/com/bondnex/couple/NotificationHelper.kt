package com.bondnex.couple

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import android.telecom.Call

object NotificationHelper {
    private const val CHANNEL_ID = "bondnex_incoming_calls_v2"
    private const val NOTIFICATION_ID = 1001

    fun showIncomingCallNotification(context: Context, call: Call) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Incoming Calls"
            val channel = NotificationChannel(
                CHANNEL_ID,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for incoming calls"
                // Ringtone setup
                val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setSound(ringtoneUri, audioAttributes)
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Caller Info
        val number = call.details?.handle?.schemeSpecificPart ?: "Unknown Caller"

        // Full Screen Intent (Launch MainActivity)
        val fullScreenIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "incoming_call")
            putExtra("number", number)
        }
        
        val fullScreenPendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            0,
            fullScreenIntent,
            fullScreenPendingIntentFlags
        )

        // Answer Action
        val answerIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "ACTION_ANSWER"
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            answerIntent,
            fullScreenPendingIntentFlags
        )

        // Decline Action
        val declineIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "ACTION_DECLINE"
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            declineIntent,
            fullScreenPendingIntentFlags
        )

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming) // Placeholder icon, replace with app icon if possible
            .setContentTitle("Incoming Call")
            .setContentText(number)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(android.R.drawable.sym_action_call, "Answer", answerPendingIntent)
            .addAction(android.R.drawable.sym_call_missed, "Decline", declinePendingIntent)

        notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build())
    }

    fun dismissIncomingCallNotification(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
