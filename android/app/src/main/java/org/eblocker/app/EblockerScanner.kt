package org.eblocker.app

import android.content.ContentValues.TAG
import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import java.net.InetAddress

class EblockerScanner(context: Context, private val listener: EblockerScannerListener) {
    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager

    private var discoveryListener: NsdManager.DiscoveryListener? = null

    private val devices: MutableMap<NsdServiceInfo, EblockerDevice> = mutableMapOf()
    fun startDiscovery() {
        if (discoveryListener != null) {
            return
        }

        discoveryListener = object : NsdManager.DiscoveryListener {

            // Called as soon as service discovery begins.
            override fun onDiscoveryStarted(regType: String) {
                Log.d(TAG, "Service discovery started")
            }

            override fun onServiceFound(service: NsdServiceInfo) {
                // A service was found! Do something with it.
                Log.d(TAG, "Service discovery success! $service")
                when {
                    service.serviceType != "_http._tcp." -> // Service type is the string containing the protocol and
                        // transport layer for this service.
                        Log.d(TAG, "Unknown Service Type: ${service.serviceType}")

                    service.serviceName.contains("eBlocker") -> nsdManager.resolveService(
                        service,
                        resolveListener
                    )
                }
            }

            override fun onServiceLost(service: NsdServiceInfo) {
                // When the network service is no longer available.
                // Internal bookkeeping code goes here.
                Log.e(TAG, "service lost: $service")
                devices[service]?.let {
                    listener.eblockerDeviceDisappeared(it)
                }
            }

            override fun onDiscoveryStopped(serviceType: String) {
                Log.i(TAG, "Discovery stopped: $serviceType")
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Discovery failed: Error code:$errorCode")
                nsdManager.stopServiceDiscovery(this)
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Discovery failed: Error code:$errorCode")
                nsdManager.stopServiceDiscovery(this)
            }
        }
        nsdManager.discoverServices(
            "_http._tcp.",
            NsdManager.PROTOCOL_DNS_SD,
            discoveryListener!!
        )
    }

    fun stopDiscovery() {
        nsdManager.stopServiceDiscovery(discoveryListener)
    }
    private val resolveListener = object : NsdManager.ResolveListener {

        override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
            // Called when the resolve fails. Use the error code to debug.
            Log.e(TAG, "Resolve failed: $errorCode")
        }

        override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
            Log.e(TAG, "Resolve Succeeded. $serviceInfo")

            val port: Int = serviceInfo.port
            val host: InetAddress = serviceInfo.host
            Log.w(TAG, "Host: ${host.hostAddress}, port: $port")
            val device = EblockerDevice(
                name = serviceInfo.serviceName,
                url = "http://${host.hostAddress}:$port",
                ipAddress = host.hostAddress!!)
            devices[serviceInfo] = device;
            listener.foundEblockerDevice(device = device)
        }
    }
}
