package com.bondnex.couple

import android.telecom.Call
import android.telecom.VideoProfile
import io.flutter.plugin.common.EventChannel

object CallManager {
    var currentCall: Call? = null
    var eventSink: EventChannel.EventSink? = null

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            sendCallEvent("call_updated", call)
        }
    }

    fun setCall(call: Call?) {
        if (currentCall != null) {
            currentCall?.unregisterCallback(callCallback)
        }
        
        currentCall = call
        
        if (call != null) {
            call.registerCallback(callCallback)
            sendCallEvent("call_added", call)
        } else {
            sendCallEvent("call_removed", null)
        }
    }

    fun answer() {
        currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
    }

    fun reject() {
        currentCall?.reject(false, null)
    }

    fun disconnect() {
        currentCall?.disconnect()
    }

    fun setMute(muted: Boolean) {
        // Mute logic usually requires AudioManager or TelecomManager, but for simplicity:
        // Not directly supported on the `Call` object. It's supported on the InCallService.
        // For BondNexInCallService we will implement it there and call it from here if needed.
    }

    fun setAudioRoute(route: Int) {
        // Handled in BondNexInCallService
    }

    private fun sendCallEvent(type: String, call: Call?) {
        if (eventSink == null) return

        val event = mutableMapOf<String, Any>("type" to type)
        
        if (call != null) {
            val callDetails = call.details
            val number = callDetails?.handle?.schemeSpecificPart ?: ""
            
            val stateString = when (call.state) {
                Call.STATE_DIALING -> "DIALING"
                Call.STATE_RINGING -> "RINGING"
                Call.STATE_ACTIVE -> "ACTIVE"
                Call.STATE_DISCONNECTED -> "DISCONNECTED"
                else -> "IDLE"
            }

            event["call"] = mapOf(
                "id" to call.hashCode().toString(),
                "number" to number,
                "state" to stateString
            )
        }
        
        // Push event to Flutter on Main Thread
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(event)
        }
    }
}
