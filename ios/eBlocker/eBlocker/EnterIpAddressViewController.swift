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

protocol EnterIpAddressDelegate: class {
    func ipAddressEntered(_ address: String)
}

class EnterIpAddressViewController: UITableViewController, UITextFieldDelegate {
    let userDefaultsIpAddressKey = "UserDefaultsIPAddressKey"
    weak var delegate: EnterIpAddressDelegate?

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IpAddressField", for: indexPath)
        let ipAddressField = cell.viewWithTag(1) as! UITextField

        if let ipAddress = UserDefaults.standard.string(forKey: userDefaultsIpAddressKey) {
            ipAddressField.text = ipAddress
        }

        ipAddressField.becomeFirstResponder()

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("eBlocker's IP address", comment: "")
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("You can find eBlocker's IP address in the settings of your router. Look for the list of devices or the list of DHCP clients.", comment: "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let enteredText = textField.text {
            let address = enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(address, forKey: userDefaultsIpAddressKey)
            delegate?.ipAddressEntered(address)
        }
        self.navigationController?.popViewController(animated: true)
        return true
    }
}
