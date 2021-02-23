//
//  ViewController.swift
//
//  Created by Ujjwal Chafle on 5/20/19.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit
import MasterCard

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var registerButton: UIButton?
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    var responseData = [String:Any]() //TODO: can be removed
    
    //MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()      
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = appVersion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(registerStatusReceived),
            name: Notification.Name("ReceivedRegisterNotification"),
            object: nil
        )
        statusLabel.isHidden=true;
        welcomeLabel.text="Welcome to \(Constant.appName) App"
        setUpRegisterButton()
    }
    //MARK:- Action methods
    
    /// Called when register button is tapped
    ///
    /// - Parameter sender: Any object
    @IBAction func register(_ sender: Any) {
        
        print(Constant.walletID)
        
        if NetworkReachabilityManager()!.isReachable {
            if registerButton?.titleLabel?.text?.caseInsensitiveCompare("register") == .orderedSame {
                /*call register method with walletId and paymentMethod parameters */
                do {
                    try PaymentHandler.shared.register(walletID: Constant.walletID,paymentType: "mcpba")
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                /*call unregister method with walletId and paymentMethod parameters */
                do {
                    try PaymentHandler.shared.unregister(walletID:Constant.walletID,paymentType: "mcpba");
                } catch {
                    print(error.localizedDescription)
                }
            }
            registerButton?.isEnabled = false
            registerButton?.backgroundColor = .gray
        } else {
            /*No network alert is displayed.*/
            showNoNetworkAlert()
        }
    }
    //MARK: Setting up reg/unreg logic
    
    /// Called when the "ReceivedRegisterNotification" notification is received. Notification is received whenever
    /// user tries to register or unregister.
    ///
    /// - Parameter notification: Notification object contains information of action and browser.
    @objc func registerStatusReceived(_ notification: Notification) {
        if let info = notification.userInfo, let name = info["action"] as? String, let status = info["status"] as? [String: Any] {
            //browser: info["browser"] as! String
            responseData = status //TODO: can be removed
            
            UserDefaults.standard.set(name, forKey: "rstatusTitle")
            let success = NSString(string: status["success"] as! String).boolValue
            UserDefaults.standard.set(success, forKey: "rstatus")
            
            let messsage = status["message"] as! String
            UserDefaults.standard.set(messsage, forKey: "message")
            let code = status["code"] as! String
            if code == "MC001" || code == "MC007" || code == "MC010" || code == "MC009" {
                UserDefaults.standard.set(code, forKey: "rCode")
            }
            UserDefaults.standard.synchronize()
            statusLabel.isHidden=false;
            setUpRegisterButton();
        }
    }
    /// Set up the registration and unregistration button
    @objc func setUpRegisterButton() {
        registerButton?.isEnabled = true
        registerButton?.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.7058823529, blue: 0.02352941176, alpha: 1)
        let statusCode = UserDefaults.standard.string(forKey: "rCode")
        
        if statusCode == "MC001" || statusCode == "MC010" {
            registerButton?.setTitle("UNREGISTER",for: .normal)
        } else if statusCode == nil || statusCode == "MC007" || statusCode == "MC009" {
            registerButton?.setTitle("REGISTER",for: .normal)
        }
        statusLabel.text = UserDefaults.standard.string(forKey: "message") ?? ""
        Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.hideLabel), userInfo: nil, repeats: false)
    }
    //MARK: - Private method
    /// Hides the status label when a scheduled timer is hit.
    @objc func hideLabel() {
        statusLabel.isHidden=true;
    }
}

