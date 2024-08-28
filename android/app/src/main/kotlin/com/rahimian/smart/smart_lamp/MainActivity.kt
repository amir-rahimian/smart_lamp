package com.rahimian.smart.smart_lamp

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var wifiAccess: WifiAccess
    private lateinit var methodChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        wifiAccess = WifiAccess(context = this, listener = object : WifiAccess.WifiAccessListener {
            override fun onWifiScanResults(success: Boolean) {
                Log.i("WIFI SERVICE", "EVENT onWifiScanResults")
                runOnUiThread {
                    methodChannel.invokeMethod("onWifiScanResults", success)
                }
            }

            override fun onNetworkJoinResult(success: Boolean, network: android.net.Network?) {
                Log.i("WIFI SERVICE", "EVENT onNetworkJoinResult : $success")
                runOnUiThread {
                    methodChannel.invokeMethod("onNetworkJoinResult", success)
                }
            }

            override fun requestWifiTurnOn() {
                Log.i("WIFI SERVICE", "EVENT requestWifiTurnOn")
                runOnUiThread {
                    methodChannel.invokeMethod("requestWifiTurnOn", null)
                }
            }

            override fun onWifiGone() {
                Log.i("WIFI SERVICE", "EVENT onWifiGone")
                runOnUiThread {
                    methodChannel.invokeMethod("onWifiGone", null)
                }
            }
        })

        methodChannel = MethodChannel(
            flutterEngine?.dartExecutor?.binaryMessenger
                ?: throw IllegalStateException("FlutterEngine is null"),
            "com.rahimian.smartlamp/wifi"
        )

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeWifiScanning" -> {
                    Log.i("WIFI SERVICE", "doing initializeWifiScanning")
                    wifiAccess.initializeWifiScanning()
                    result.success(null)
                }

                "tryConnectToWifi" -> {
                    Log.i("WIFI SERVICE", "doing tryConnectToWifi")
                    val ssid = call.argument<String>("ssid") ?: ""
                    val pass = call.argument<String>("pass") ?: ""
                    val wifi = wifiAccess.getWifiList().first { it.ssid == ssid }
                    Log.i("WIFI SERVICE", "on WIFI :${wifi.ssid}")
                    wifiAccess.tryConnectToWifi(wifi, pass)
                    result.success(null)
                }

                "getWifiList" -> {
                    val wifiList = wifiAccess.getWifiList().map { wifi ->
                        mapOf(
                            "ssid" to wifi.ssid,
                            "waveLevel" to wifi.waveLevel,
                            "securityType" to wifi.securityType
                        )
                    }
                    Log.i("WIFI SERVICE", "getWifiList : $wifiList")
                    result.success(wifiList)
                }

                "disconnect" -> {
                    wifiAccess.disconnect()
                    Log.i("WIFI SERVICE", "disconnect called!")
                    result.success(null)
                }

                "openWifi" -> {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        wifiAccess.cleanup()
    }
}