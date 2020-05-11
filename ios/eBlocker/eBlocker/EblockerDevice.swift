/*
 * Copyright 2020 eBlocker Open Source UG (haftungsbeschraenkt)
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be
 * approved by the European Commission - subsequent versions of the EUPL
 * (the "License"); You may not use this work except in compliance with
 * the License. You may obtain a copy of the License at:
 *
 *   https://joinup.ec.europa.eu/page/eupl-text-11-12
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import Foundation

enum EblockerDeviceState: String, Decodable {
    case UNKNOWN // Initial state
    case OFFLINE // API not reachable

    // The following states must be kept in sync with
    // https://github.com/eblocker/eblocker/blob/develop/eblocker-icapserver/src/main/java/org/eblocker/server/common/data/systemstatus/ExecutionState.java
    case SHUTTING_DOWN
    case BOOTING
    case RUNNING
    case ERROR
    case SHUTTING_DOWN_FOR_REBOOT
    case UPDATING
}

enum EblockerRegistrationState: String, Decodable {
    case UNKNOWN // Initial state
    case NEW
    case OK
    case INVALID
    case REVOKED
}

class EblockerDevice: Equatable {
    var name: String
    var url: URL
    var ipAddress: String?
    var osVersion: String?
    var productName: String?
    var state: EblockerDeviceState
    var registrationState: EblockerRegistrationState
    var createdManually: Bool

    init(name: String, url: URL) {
        self.name = name
        self.url = url
        self.state = .UNKNOWN
        self.registrationState = .UNKNOWN
        self.createdManually = false
    }

    static func == (lhs: EblockerDevice, rhs: EblockerDevice) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url
    }

    var dashboardUrl: URL {
        get {
            return url.appendingPathComponent("dashboard/")
        }
    }

    var key: String {
        get {
            return url.absoluteString
        }
    }
}
