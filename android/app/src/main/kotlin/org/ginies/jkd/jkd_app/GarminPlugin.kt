package org.ginies.jkd.jkd_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.ConnectIQ.IQConnectType
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GarminPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "org.ginies.jkd/garmin"
        const val EVENT_CHANNEL = "org.ginies.jkd/garmin_events"
        const val WATCH_APP_UUID = "327dd6a7-81ee-4125-b60d-897d7e28d196"
    }

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var connectIQ: ConnectIQ? = null
    private var pairedDevices: List<IQDevice> = emptyList()

    fun initialize() {
        try {
            connectIQ = ConnectIQ.getInstance(context, IQConnectType.WIRELESS)
            connectIQ?.initialize(context, false, object : ConnectIQ.ConnectIQListener {
                override fun onSdkReady() {
                    pairedDevices = connectIQ?.knownDevices ?: emptyList()
                    sendEvent(mapOf("type" to "sdkReady", "deviceCount" to pairedDevices.size))
                    registerForMessages()
                }

                override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                    sendEvent(mapOf("type" to "error", "message" to "SDK init error: ${status.name}"))
                }

                override fun onSdkShutDown() {
                    sendEvent(mapOf("type" to "sdkShutdown"))
                }
            })
        } catch (e: Exception) {
            sendEvent(mapOf("type" to "error", "message" to "ConnectIQ init failed: ${e.message}"))
        }
    }

    private fun registerForMessages() {
        val ciq = connectIQ ?: return
        val watchApp = IQApp(WATCH_APP_UUID)
        for (device in pairedDevices) {
            try {
                ciq.registerForAppEvents(device, watchApp) { _, _, messageData, status ->
                    if (status == ConnectIQ.IQMessageStatus.SUCCESS && messageData != null) {
                        for (item in messageData) {
                            if (item is Map<*, *>) {
                                val data = item.entries.associate { it.key.toString() to it.value }
                                sendEvent(mapOf("type" to "message", "data" to data))
                            }
                        }
                    }
                }
                ciq.registerForDeviceEvents(device) { dev, status ->
                    sendEvent(mapOf(
                        "type" to "deviceStatus",
                        "deviceId" to dev.deviceIdentifier,
                        "status" to status.name
                    ))
                }
            } catch (e: Exception) {
                sendEvent(mapOf("type" to "error", "message" to "registerForMessages failed: ${e.message}"))
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                initialize()
                result.success(null)
            }
            "isWatchConnected" -> {
                val connected = pairedDevices.any { it.status == IQDevice.IQDeviceStatus.CONNECTED }
                result.success(connected)
            }
            "getPairedDevices" -> {
                val list = pairedDevices.map {
                    mapOf("id" to it.deviceIdentifier, "name" to it.friendlyName, "status" to it.status.name)
                }
                result.success(list)
            }
            "sendTtsComplete" -> {
                sendTtsComplete()
                result.success(null)
            }
            "shutdown" -> {
                shutdown()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendEvent(data: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(data) }
    }

    private fun sendTtsComplete() {
        val ciq = connectIQ ?: return
        val watchApp = IQApp(WATCH_APP_UUID)
        for (device in pairedDevices) {
            if (device.status == IQDevice.IQDeviceStatus.CONNECTED) {
                try {
                    ciq.sendMessage(device, watchApp, mapOf("ttsComplete" to true),
                        object : ConnectIQ.IQSendMessageListener {
                            override fun onMessageStatus(d: IQDevice?, a: IQApp?, s: ConnectIQ.IQMessageStatus?) {}
                        })
                } catch (e: Exception) {
                    sendEvent(mapOf("type" to "error", "message" to "sendTtsComplete failed: ${e.message}"))
                }
            }
        }
    }

    fun shutdown() {
        try {
            connectIQ?.unregisterAllForEvents()
            connectIQ?.shutdown(context)
        } catch (_: Exception) {}
    }
}
