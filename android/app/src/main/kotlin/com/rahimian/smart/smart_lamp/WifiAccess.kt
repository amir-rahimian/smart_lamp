package com.rahimian.smart.smart_lamp


import android.Manifest.permission.ACCESS_FINE_LOCATION
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import androidx.core.content.ContextCompat

class WifiAccess(
    private val context: Context, private val listener: WifiAccessListener
) {
    private val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private lateinit var wifiScanReceiver: BroadcastReceiver
    private lateinit var networkCallback: ConnectivityManager.NetworkCallback
    private val wifiList = ArrayList<Wifi>()
    private lateinit var scanResults: MutableList<ScanResult>

    fun initializeWifiScanning() {
        wifiScanReceiver = object : BroadcastReceiver() {
            @SuppressLint("MissingPermission")
            override fun onReceive(context: Context, intent: Intent) {
                val success = intent.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false)
                if (success) updateWifiList(wifiManager.scanResults)
                listener.onWifiScanResults(success)
            }
        }
        context.registerReceiver(
            wifiScanReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
        )
        checkWifiAndRequestTurnOn()
    }

    private fun checkWifiAndRequestTurnOn() {
        if (!wifiManager.isWifiEnabled) listener.requestWifiTurnOn()
    }

    private fun updateWifiList(results: MutableList<ScanResult>): ArrayList<Wifi> {
        scanResults = results
        wifiList.clear()
        results.mapTo(wifiList) { result ->
            Wifi(
                ssid = result.SSID, waveLevel = result.level, securityType = when {
                    result.capabilities.contains(SECURITY_TYPE_WPA3) -> SECURITY_TYPE_WPA3
                    result.capabilities.contains(SECURITY_TYPE_WPA2) -> SECURITY_TYPE_WPA2
                    result.capabilities.contains(SECURITY_TYPE_WPA) -> SECURITY_TYPE_WPA
                    else -> SECURITY_TYPE_NA
                }
            )
        }
        return wifiList;
    }

    fun getWifiList(): ArrayList<Wifi> {
        if (ContextCompat.checkSelfPermission(
                context, ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) return updateWifiList(wifiManager.scanResults)
        else return arrayListOf()
    }

    fun tryConnectToWifi(wifi: Wifi, pass: String) {
        val specifier = WifiNetworkSpecifier.Builder().setSsid(wifi.ssid).apply {
            when (wifi.securityType) {
                SECURITY_TYPE_WPA3 -> setWpa3Passphrase(pass)
                SECURITY_TYPE_WPA2 -> setWpa2Passphrase(pass)
                else -> setWpa2Passphrase(pass)
            }

        }.build()

        val request = NetworkRequest.Builder().addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .setNetworkSpecifier(specifier).build()

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                connectivityManager.bindProcessToNetwork(network)
                listener.onNetworkJoinResult(true, network)
            }

            override fun onUnavailable() {
                listener.onNetworkJoinResult(false, null)
            }

            override fun onLost(network: Network) {
                listener.onWifiGone()
            }
        }
        connectivityManager.unregisterNetworkCallbackSafe(networkCallback)

        connectivityManager.requestNetwork(request, networkCallback)
    }

    fun disconnect() {
        connectivityManager.unregisterNetworkCallbackSafe(networkCallback)
    }

    fun cleanup() {
        context.unregisterReceiverSafe(wifiScanReceiver)
        connectivityManager.unregisterNetworkCallbackSafe(networkCallback)
    }

    private fun Context.unregisterReceiverSafe(receiver: BroadcastReceiver) {
        try {
            unregisterReceiver(receiver)
        } catch (e: IllegalArgumentException) {
            // Receiver not registered
        }
    }

    private fun ConnectivityManager.unregisterNetworkCallbackSafe(callback: ConnectivityManager.NetworkCallback) {
        try {
            unregisterNetworkCallback(callback)
        } catch (e: IllegalArgumentException) {
            // Callback not registered
        }
    }

    interface WifiAccessListener {
        fun onWifiScanResults(success: Boolean)
        fun onNetworkJoinResult(success: Boolean, network: Network?)
        fun requestWifiTurnOn()
        fun onWifiGone()
    }

    companion object {
        const val SECURITY_TYPE_WPA3 = "WPA3"
        const val SECURITY_TYPE_WPA2 = "WPA2"
        const val SECURITY_TYPE_WPA = "WPA"
        const val SECURITY_TYPE_NA = "N/A"
    }
}

data class Wifi(
    val ssid: String,
    val waveLevel: Int,
    val securityType: String
)
