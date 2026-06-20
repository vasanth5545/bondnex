package com.bondnex.couple

import android.Manifest
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.CallAudioState
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.bondnex/dialer"
    private val EVENT_CHANNEL = "com.bondnex/call_events"
    private val ROLE_REQUEST_CODE = 100

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup Event Channel for listening to Call state changes
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CallManager.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    CallManager.eventSink = null
                }
            }
        )

        // Setup Method Channel for commands from Flutter to Kotlin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDefaultDialer" -> {
                    requestDefaultDialerRole()
                    result.success(true)
                }
                "isDefaultDialer" -> {
                    val isDefault = checkDefaultDialerRole()
                    result.success(isDefault)
                }
                "makeCall" -> {
                    val number = call.argument<String>("number")
                    if (number != null) {
                        val success = placeCallWithSim(number, 0)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "Phone number missing", null)
                    }
                }
                "answerCall" -> {
                    CallManager.answer()
                    result.success(true)
                }
                "rejectCall" -> {
                    CallManager.reject()
                    result.success(true)
                }
                "disconnectCall" -> {
                    CallManager.disconnect()
                    result.success(true)
                }
                "setMute" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    BondNexInCallService.instance?.setMute(muted)
                    result.success(true)
                }
                "setAudioRoute" -> {
                    val routeStr = call.argument<String>("route")
                    val route = if (routeStr == "SPEAKER") CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE
                    BondNexInCallService.instance?.setAudio(route)
                    result.success(true)
                }
                "getSimCards" -> {
                    val simCards = getSimCards()
                    result.success(simCards)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestDefaultDialerRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (!roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                startActivityForResult(intent, ROLE_REQUEST_CODE)
            }
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivity(intent)
        }
    }

    private fun checkDefaultDialerRole(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            return roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                return telecomManager.defaultDialerPackage == packageName
            }
            return false
        }
    }

    private fun getSimCards(): List<Map<String, Any>> {
        val simList = mutableListOf<Map<String, Any>>()
        
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return simList
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val activeSubscriptionInfoList: List<SubscriptionInfo>? = subscriptionManager.activeSubscriptionInfoList

            activeSubscriptionInfoList?.forEach { info ->
                val simData = mapOf(
                    "carrierName" to (info.carrierName?.toString() ?: "Unknown"),
                    "displayName" to (info.displayName?.toString() ?: "SIM"),
                    "slotIndex" to info.simSlotIndex,
                    "subscriptionId" to info.subscriptionId
                )
                simList.add(simData)
            }
        }
        return simList
    }

    private fun placeCallWithSim(phoneNumber: String, simSlotIndex: Int): Boolean {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val uri = Uri.fromParts("tel", phoneNumber, null)
            val extras = Bundle()
            
            try {
                telecomManager.placeCall(uri, extras)
                return true
            } catch (e: SecurityException) {
                return false
            }
        } else {
            return false
        }
    }
}
