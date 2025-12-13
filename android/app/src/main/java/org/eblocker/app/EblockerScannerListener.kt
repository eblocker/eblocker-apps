package org.eblocker.app

interface EblockerScannerListener {
    fun foundEblockerDevice(device: EblockerDevice)
    fun eblockerDeviceDisappeared(device: EblockerDevice)
}