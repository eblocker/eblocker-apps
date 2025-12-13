package org.eblocker.app

enum class EblockerDeviceState {
    UNKNOWN, // Initial state
    OFFLINE, // API not reachable

    // The following states must be kept in sync with
    // https://github.com/eblocker/eblocker/blob/develop/eblocker-icapserver/src/main/java/org/eblocker/server/common/data/systemstatus/ExecutionState.java
    SHUTTING_DOWN,
    BOOTING,
    RUNNING,
    ERROR,
    SHUTTING_DOWN_FOR_REBOOT,
    UPDATING
}

enum class EblockerRegistrationState {
    UNKNOWN, // Initial state
    NEW,
    OK,
    INVALID,
    REVOKED
}

data class EblockerDevice(
    val name: String,
    val url: String,
    val ipAddress: String,
    var osVersion: String? = null,
    var productName: String? = null,
    var state: EblockerDeviceState = EblockerDeviceState.UNKNOWN,
    var registrationState: EblockerRegistrationState = EblockerRegistrationState.UNKNOWN
) {
}
