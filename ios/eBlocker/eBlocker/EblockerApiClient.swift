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

// These structs can be decoded from JSON:
struct EblockerSystemStatus: Decodable {
    var executionState: EblockerDeviceState
    var projectVersion: String
}

struct EblockerProductInfo: Decodable {
    var productName: String
}

struct EblockerRegistration: Decodable {
    var registrationState: EblockerRegistrationState
    var deviceName: String? // only if registered
    var productInfo: EblockerProductInfo? // only if registered
}

// An ApiResult is either one of the structs above
// or an error
enum ApiResult<T: Decodable> {
    case success(T)
    case error(Error)
}

// Only when both results are collected, the device should be updated:
struct EblockerApiResults {
    var systemStatus: ApiResult<EblockerSystemStatus>?
    var registration: ApiResult<EblockerRegistration>?
}

enum EblockerApiError: Error {
    case invalidHttpStatus(status: Int)
    case missingHttpStatus
}

class EblockerApiClient {
    private var urlSession: URLSession
    private let decoder = JSONDecoder()
    weak var delegate: EblockerApiClientDelegate?
    let systemStatusPath = "/api/adminconsole/systemstatus" // eOS 2.0 and higher
    let systemStatusPathLegacy = "/api/systemstatus" // eOS 1.11
    let registrationPath = "/registration"

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 3.0
        configuration.timeoutIntervalForResource = 3.0
        self.urlSession = URLSession(configuration: configuration)
    }

    func updateEblockerDeviceData(device: EblockerDevice) {
        //NSLog(">>> Updating data for device %@", device.name)
        let baseUrl = device.url
        let systemStatusUrl       = baseUrl.appendingPathComponent(systemStatusPath)
        let systemStatusUrlLegacy = baseUrl.appendingPathComponent(systemStatusPathLegacy)
        let registrationUrl       = baseUrl.appendingPathComponent(registrationPath)

        var results = EblockerApiResults()

        // both API calls --- system status and registration --- must be completed:
        func continuation() {
            if results.systemStatus == nil || results.registration == nil {
                return
            }
            processResults(results: results, device: device)
        }

        get(systemStatusUrl) { (result: ApiResult<EblockerSystemStatus>) in
            switch result {
            case .error(EblockerApiError.invalidHttpStatus(status: 404)):
                // try the legacy URL:
                results.systemStatus = nil
                self.get(systemStatusUrlLegacy) { (result: ApiResult<EblockerSystemStatus>) in
                    results.systemStatus = result
                    continuation()
                }
            default:
                results.systemStatus = result
                continuation()
            }
        }

        get(registrationUrl) { (result: ApiResult<EblockerRegistration>) in
            results.registration = result
            continuation()
        }
    }

    private func processResults(results: EblockerApiResults, device: EblockerDevice) {
        // Note: statusResult and registrationResult cannot be nil, see: func continuation()
        switch results.systemStatus! {
        case let .success(systemStatus):
            device.osVersion = systemStatus.projectVersion
            device.state = systemStatus.executionState
        case let .error(error):
            NSLog("SystemStatus call returned an error: %@", error.localizedDescription)
            device.state = .OFFLINE
        }

        switch results.registration! {
        case let .success(registration):
            device.registrationState = registration.registrationState
            if let deviceName = registration.deviceName {
                device.name = deviceName
            }
            if let productName = registration.productInfo?.productName {
                device.productName = EblockerApiClient.normalize(productName: productName)
            }
        case let .error(error):
            NSLog("Registration API call returned an error: %@", error.localizedDescription)
        }

        deviceDataUpdated(device: device)
    }

    private func deviceDataUpdated(device: EblockerDevice) {
        DispatchQueue.main.async {
            self.delegate?.deviceDataUpdated(device: device)
        }
    }

    // Get and decode a JSON object from the backend.
    // When the data arrives or an error occurs, the given
    // completion handler is called.
    private func get<T>(_ url: URL, completionHandler: @escaping (ApiResult<T>) -> Void) {
        let task = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let e = error {
                completionHandler(.error(e))
            } else {
                if let r = response as? HTTPURLResponse {
                    if r.statusCode == 200 {
                        do {
                            let obj = try self.decoder.decode(T.self, from: data!)
                            completionHandler(.success(obj))
                        } catch {
                            completionHandler(.error(error))
                        }
                    } else {
                        completionHandler(.error(EblockerApiError.invalidHttpStatus(status: r.statusCode)))
                    }
                } else {
                    completionHandler(.error(EblockerApiError.missingHttpStatus))
                }
            }
        }
        task.resume()
    }

    private static func normalize(productName: String) -> String {
        // e.g. remove "(Cube)" from product name
        return productName.replacingOccurrences(of: " ?\\(.*?\\)", with: "", options: .regularExpression)
    }
}
