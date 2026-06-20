package com.bondnex.couple

import android.telecom.Call
import android.telecom.InCallService

class BondNexInCallService : InCallService() {

    companion object {
        var instance: BondNexInCallService? = null
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        instance = this
        CallManager.setCall(call)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        CallManager.setCall(null)
        if (CallManager.currentCall == null) {
            instance = null
        }
    }

    fun setMute(muted: Boolean) {
        setMuted(muted)
    }

    fun setAudio(route: Int) {
        setAudioRoute(route)
    }
}
