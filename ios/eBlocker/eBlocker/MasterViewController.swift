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

import UIKit
import SafariServices

class MasterViewController: UITableViewController, EblockerScannerDelegate, EnterIpAddressDelegate, EblockerApiClientDelegate {
    private let eBlockerDefaultPort = 3000
    private let showHintsAfterMilliseconds = 1000
    private let refreshDeviceDataAfterMilliseconds = 5000
    private var devices = [EblockerDevice]()
    private let scanner = EblockerScanner()
    private let apiClient = EblockerApiClient()
    private var hintsView: UIView?
    private var deviceDataRefreshTimer: Timer?
    private var showingDeviceNotFoundAlert = false

    override func awakeFromNib() {
        super.awakeFromNib()
        //NSLog("Awoke from nib")

        // Get notified when the app comes into the foreground:
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { (notification) in
            //NSLog("Notification: App did become active")
            self.startScanning()
        }

        // Get notified when the app goes into the background:
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { (notification) in
            //NSLog("Notification: App will resign active")
            self.stopScanning()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scanner.delegate = self
        apiClient.delegate = self

        // Remove the header and re-add it after n seconds:
        self.hintsView = tableView.tableHeaderView
        tableView.tableHeaderView = nil
        asyncAfter(milliseconds: showHintsAfterMilliseconds) {
            self.updateHints()
        }
        // get rid of extra separator lines in the table:
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }

    private func asyncAfter(milliseconds: Int, work: @escaping () -> Void) {
        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(milliseconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            work()
        }
    }

    private func updateHints() {
        if devices.count == 0 {
            tableView.tableHeaderView = hintsView
        } else {
            tableView.tableHeaderView = nil
        }
    }

    private func startScanning() {
        //NSLog("Starting scanning")
        scanner.start()
        deviceDataRefreshTimer = Timer(timeInterval: 5.0, target: self, selector: #selector(refreshDevicesData), userInfo: nil, repeats: true)
        RunLoop.main.add(deviceDataRefreshTimer!, forMode: RunLoop.Mode.default)
   }

    private func stopScanning() {
        //NSLog("Stopping scanning")
        scanner.stop();
        deviceDataRefreshTimer?.invalidate()
        deviceDataRefreshTimer = nil
    }

    @objc private func refreshDevicesData() {
        for device in devices {
            apiClient.updateEblockerDeviceData(device: device)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OverviewCell", for: indexPath)

        configure(cell: cell, indexPath: indexPath)

        return cell
    }

    private func configure(cell: UITableViewCell, indexPath: IndexPath) {
        let device = devices[indexPath.row]
        let labelName = cell.viewWithTag(1) as! UILabel
        labelName.text = device.name

        let labelIp = cell.viewWithTag(2) as! UILabel
        labelIp.text = device.ipAddress

        // Content set asynchronously:
        let labelVersion = cell.viewWithTag(3) as! UILabel
        if let version = device.osVersion {
            labelVersion.text = "eOS " + version
        } else {
            labelVersion.text = NSLocalizedString("eOS (unknown version)", comment: "")
        }

        let labelStateOrProduct = cell.viewWithTag(4) as! UILabel
        let spinner = cell.viewWithTag(5) as! UIActivityIndicatorView
        setStateAndProduct(device: device, label: labelStateOrProduct, spinner: spinner)

        let activateLicenseButton = cell.viewWithTag(6) as! UIButton
        let stackViewStateOrProduct = cell.viewWithTag(7) as! UIStackView
        configureActivateLicenseButton(device: device, activateLicenseButton: activateLicenseButton, alternativeView: stackViewStateOrProduct)
    }

    private func setStateAndProduct(device: EblockerDevice, label: UILabel, spinner: UIActivityIndicatorView) {
        switch device.state {
        case .RUNNING: // Show product name if available. Otherwise, the eBlocker is not registered yet.
            if let productName = device.productName {
                label.text = productName
            } else {
                label.text = NSLocalizedString("(not registered)", comment: "")
            }

        // initial state, API response not available yet:
        case .UNKNOWN:  label.text = NSLocalizedString("Connecting", comment: "")
        case .BOOTING:  label.text = NSLocalizedString("Booting", comment: "")
        case .ERROR:    label.text = NSLocalizedString("Error", comment: "")
        case .OFFLINE:  label.text = NSLocalizedString("Offline", comment: "")
        case .UPDATING: label.text = NSLocalizedString("Installing update", comment: "")
        case .SHUTTING_DOWN: label.text = NSLocalizedString("Shutting down", comment: "")
        case .SHUTTING_DOWN_FOR_REBOOT: label.text = NSLocalizedString("Rebooting", comment: "")
        }

        switch device.state {
        case .RUNNING, .ERROR, .OFFLINE:
            spinner.stopAnimating()
        default:
            spinner.startAnimating()
        }
    }

    private func configureActivateLicenseButton(device: EblockerDevice, activateLicenseButton: UIButton, alternativeView: UIView) {
        if device.registrationState == .NEW && device.state == .RUNNING {
            activateLicenseButton.isHidden = false
        } else {
            activateLicenseButton.isHidden = true
        }
        alternativeView.isHidden = !activateLicenseButton.isHidden
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            devices.remove(at: indexPath.section)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    // Note: the setting in the storyboard for the prototype cell's custom row height is ignored
    // for dynamic cells. So we implement this method.
    // However: we also set the custom row height in Interface Builder for easier layout.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }

    func foundEblockerDevice(device: EblockerDevice) {
        devices.append(device)
        self.tableView.reloadData()
        updateHints()

        // Update meta-data about devices in the background:
        // This will call back deviceDataUpdated()
        apiClient.updateEblockerDeviceData(device: device)
    }

    // EblockerApiClientDelegate
    func deviceDataUpdated(device: EblockerDevice) {
        if let i = devices.firstIndex(where: {(dev) -> Bool in return dev == device}) {
            let indexPath = IndexPath(row: i, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                configure(cell: cell, indexPath: indexPath)
            }
            if device.createdManually && device.state == .OFFLINE {
                showDeviceNotFoundAlert(device: device)
            }
        }
    }

    private func showDeviceNotFoundAlert(device: EblockerDevice) {
        if showingDeviceNotFoundAlert {
            return
        }
        let title = NSLocalizedString("eBlocker not found", comment: "")
        let message = String(format: NSLocalizedString("No eBlocker could be found at address %@", comment: ""),
                             device.ipAddress!)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.showingDeviceNotFoundAlert = false
            self.eblockerDeviceDisappeared(device: device)
        })
        self.showingDeviceNotFoundAlert = true
        self.present(alert, animated: true, completion: nil)
    }

    func eblockerDeviceDisappeared(device: EblockerDevice) {
        if let i = devices.firstIndex(where: {(dev) -> Bool in return dev == device}) {
            devices.remove(at: i)
            self.tableView.reloadData()
            updateHints()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EnterIpAddress" {
            let enterIpAddressVC = segue.destination as! EnterIpAddressViewController
            enterIpAddressVC.delegate = self
        }
    }

    // Local IPv4 addresses are routed to HTTP port 3000.
    // Other addresses and FQDNs are routed to HTTPS port 443.
    func ipAddressEntered(_ address: String) {
        var urlString = String(format: "https://%@", address)
        if let addressNum = ipv4ToInt(address: address) {
            if isLocalIpv4Address(address: addressNum) {
                urlString = String(format: "http://%@:%d", address, eBlockerDefaultPort)
            }
        }
        if let url = URL(string: urlString) {
            let device = EblockerDevice(name: "eBlocker", url: url)
            device.createdManually = true
            device.ipAddress = address
            foundEblockerDevice(device: device)
        }
    }

    @IBAction func openEblockerSettings(sender: UIButton) {
        if let row = rowOfButton(button: sender) {
            let device = devices[row]
            openWebView(url: device.url)
        }
    }
    
    @IBAction func openEblockerDashboard(sender: UIButton) {
        if let row = rowOfButton(button: sender) {
            let device = devices[row]
            openWebView(url: device.dashboardUrl)
        }
    }

    @IBAction func openHelp(sender: Any) {
        if let url = URL(string: NSLocalizedString("https://eblocker.org/app-help-en", comment: "")) {
            openWebView(url: url)
        }
    }

    private func openWebView(url: URL) {
        let svc = SFSafariViewController(url: url)
        self.present(svc, animated: true, completion: nil)
    }

    private func openExternalBrowser(url: URL) {
        UIApplication.shared.openURL(url)
    }

    private func rowOfButton(button: UIView) -> Int? {
        let buttonPosition = button.convert(CGPoint.zero, to: tableView)
        let indexPath = tableView.indexPathForRow(at: buttonPosition)
        return indexPath?.row
    }
}

