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

// Returns an IPv4 address as a string when the given Data objects contains
// a sockaddr_in struct.
func unpackIpv4Address(data: Data) -> String? {
    let socketAddress = data.withUnsafeBytes {
        return $0.load(as: sockaddr.self)
    }
    if socketAddress.sa_family == AF_INET {
        let socketAddressInet = data.withUnsafeBytes {
            return $0.load(as: sockaddr_in.self)
        }
        if let str = String(cString: inet_ntoa(socketAddressInet.sin_addr), encoding: .ascii) {
            return str
        }
    }

    return nil
}

func ipv4ToInt(address: String) -> UInt32? {
    let parts = address.split(separator: ".")
    guard parts.count == 4 else { return nil }
    var result: UInt32 = 0
    for i in 0...3 {
        guard let num = UInt32(parts[i]) else { return nil }
        guard num < 256 else { return nil }
        let offset = (-i + 3)*8
        result += num << offset
    }
    return result
}

struct LocalIpv4Network {
    var address: UInt32
    var prefixLength: Int

    init(_ address: String, _ prefixLength: Int) {
        self.address = ipv4ToInt(address: address)!
        self.prefixLength = prefixLength
    }

    func contains(_ address: UInt32) -> Bool {
        let offset = 32 - prefixLength
        return (self.address >> offset) == (address >> offset)
    }
}

let localIpv4Networks = [
    LocalIpv4Network("10.0.0.0", 8),
    LocalIpv4Network("172.16.0.0", 12),
    LocalIpv4Network("192.168.0.0", 16),
    LocalIpv4Network("169.254.0.0", 16)
]

func isLocalIpv4Address(address: UInt32) -> Bool {
    for localNetwork in localIpv4Networks {
        if localNetwork.contains(address) {
            return true
        }
    }
    return false
}
