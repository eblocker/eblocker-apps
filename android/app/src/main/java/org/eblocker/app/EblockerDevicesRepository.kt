package org.eblocker.app

import android.app.Application
import android.content.ContentValues.TAG
import android.content.Context
import android.util.Log
import androidx.lifecycle.MutableLiveData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONObject

class EblockerDevicesRepository(val context: Context) {
    val currentEblockers = MutableLiveData<List<EblockerDevice>>()
    var eblockers = mutableListOf<EblockerDevice>()
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    init {
        Log.w(TAG, "Initializing EblockerDevicesRepository")
        coroutineScope.launch(Dispatchers.IO) {
            var eblockers = mutableListOf<EblockerDevice>()
            startScanning()
        }
    }
    private fun startScanning() {
        val scanner = EblockerScanner(context, object: EblockerScannerListener {
            override fun foundEblockerDevice(device: EblockerDevice) {
                Log.w(TAG, "Found eBlocker: $device")
                eblockers.add(device)
                updateUI()
                val client = ApiClient(device.url)
                coroutineScope.launch(Dispatchers.IO) {
                    val registration = client.getRegistration()
                    Log.w(TAG, "Got registration: $registration")
                    val productInfo = registration.get("productInfo") as JSONObject
                    val productName = productInfo.get("productName") as String
                    device.registrationState = EblockerRegistrationState.valueOf(registration.get("registrationState") as String)
                    device.productName = productName
                    updateUI()
                }
                coroutineScope.launch(Dispatchers.IO) {
                    val systemStatus = client.getSystemStatus()
                    Log.w(TAG, "Got system status: $systemStatus")
                    device.state = EblockerDeviceState.valueOf(systemStatus.get("executionState") as String)
                    device.osVersion = systemStatus.get("projectVersion") as String
                    updateUI()
                }
            }

            override fun eblockerDeviceDisappeared(device: EblockerDevice) {
                Log.w(TAG, "Lost eBlocker: $device")
            }
        })

        scanner.startDiscovery()
            /*onDispose {
                scanner.stopDiscovery()
            }*/
    }

    fun updateUI() {
        // Deep copy the list:
        val eblockersNew = eblockers.map {device -> device.copy()}
        currentEblockers.postValue(eblockersNew)
    }
}
