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

class EblockerScanner: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    let browser = NetServiceBrowser()
    var services = Set<NetService>()
    var devices = Dictionary<NetService, EblockerDevice>()
    weak var delegate: EblockerScannerDelegate?

    func start() {
        browser.delegate = self
        browser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
        
    }
    
    func stop() {
        browser.stop()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        //NSLog("Found Bonjour service: %@", service);
        service.delegate = self
        service.resolve(withTimeout:5)
        services.insert(service) // must retain the service to resolve it
    }
    
    func netServiceDidResolveAddress(_ service: NetService) {
        //NSLog("%@ resolved addresses", service.name)
        var addressOrHost: String?
        var ipAddress: String?
        if let addresses = service.addresses {
            for address in addresses {
                if let str = unpackIpv4Address(data: address) {
                    ipAddress = str
                    addressOrHost = str
                }
            }
        }
        //NSLog("  Port: %d", service.port)
        if let hostName = service.hostName {
            //NSLog("  Hostname: %@", hostName)
            if !hostName.starts(with: "eblocker") {
                //NSLog("  -> Ignoring non-eBlocker device")
                return
            }

            if addressOrHost == nil {
                addressOrHost = hostName
            }
            let urlString = "http://" + addressOrHost! + ":" + String(service.port)
            if let url = URL(string: urlString) {
                let device = EblockerDevice(name: service.name, url: url)
                device.ipAddress = ipAddress
                devices[service] = device
                delegate?.foundEblockerDevice(device: device)
            } else {
                //NSLog("Could not build URL for %@", service.name)
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.remove(service)
        if let device = devices.removeValue(forKey: service) {
            delegate?.eblockerDeviceDisappeared(device: device)
        }
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        //NSLog("The net service browser will search")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        //NSLog("The net service browser did stop search")
    }
}
