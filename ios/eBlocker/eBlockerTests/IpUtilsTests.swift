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

import XCTest

class IpUtilsTests: XCTestCase {
    func testIpv4ToInt() {
        let ip: UInt32 = 3232241450 // (192 << 24) + (168 << 16) + (23 << 8) + 42
        XCTAssertEqual(ipv4ToInt(address: "192.168.23.42"), ip)

        XCTAssertEqual(ipv4ToInt(address: "0.0.0.0"), 0)
        XCTAssertEqual(ipv4ToInt(address: "255.255.255.255"), 0xFFFFFFFF)
        XCTAssertEqual(ipv4ToInt(address: "1.1.1.1"), 0x01010101)
        XCTAssertEqual(ipv4ToInt(address: "9.9.9.9"), 0x09090909)

        XCTAssertNil(ipv4ToInt(address: "192.168.0"))
        XCTAssertNil(ipv4ToInt(address: "192.168.0.256"))
        XCTAssertNil(ipv4ToInt(address: "www.google.com"))
        XCTAssertNil(ipv4ToInt(address: "fritz.box"))
        XCTAssertNil(ipv4ToInt(address: "localhost"))
    }

    func testIsLocalIpv4Network() {
        XCTAssertTrue(isLocalIpv4Address(address: ipv4ToInt(address: "10.10.10.10")!))
        XCTAssertTrue(isLocalIpv4Address(address: ipv4ToInt(address: "169.254.0.255")!))
        XCTAssertTrue(isLocalIpv4Address(address: ipv4ToInt(address: "192.168.42.23")!))
        XCTAssertTrue(isLocalIpv4Address(address: ipv4ToInt(address: "172.23.1.55")!))

        XCTAssertFalse(isLocalIpv4Address(address: ipv4ToInt(address: "9.10.10.10")!))
        XCTAssertFalse(isLocalIpv4Address(address: ipv4ToInt(address: "196.254.0.255")!))
        XCTAssertFalse(isLocalIpv4Address(address: ipv4ToInt(address: "192.169.42.23")!))
        XCTAssertFalse(isLocalIpv4Address(address: ipv4ToInt(address: "172.32.0.0")!))
    }
}
