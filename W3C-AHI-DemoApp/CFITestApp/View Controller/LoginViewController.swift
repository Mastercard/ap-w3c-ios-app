//
//  LoginViewController.swift
//
//  Created by Ujjwal Chafle on 5/30/19.
//  Copyright © 2021 Mastercard. All rights reserved.
//  MasterCard Test CFI

import UIKit
import LocalAuthentication
import MasterCard
//

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    var paymentRequestEvent: PaymentRequestEvent?
    var context = LAContext()
    var item: [String:Any]?
    let paymentVC = PaymentViewController()
    
    //MARK: - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "\(Constant.appName) Login";
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (UIApplication.shared.delegate as! AppDelegate).hasPaymentRequested == true {
            if NetworkReachabilityManager()!.isReachable {
                do {
                    try handlePaymentRequestEvent()
                } catch {
                    print("Error")
                    (UIApplication.shared.delegate as! AppDelegate).hasPaymentRequested = false
                    let response = ["code": "AHI5012", "message": "Failed to validate payment request"]
                    let failedEncodedString = Utility.failureResponse(apiName: error.localizedDescription, apiResponse: response, requestId: paymentRequestEvent?.paymentRequestId)
                    self.handlerUnauthorisedPayment(encodedPaymentObject: failedEncodedString, message: "Error processing the request. Please try again")
                }
            } else {
                ///No network alert is displayed.
                self.showNoNetworkAlert()
            }
        } else {
            authWithTouchID()
        }
    }
    //MARK: - Action method
    /// Called when login button is tapped.
    ///
    /// - Parameter sender: Any object
    @IBAction func loginAction(_ sender: Any) {
        validateAndLaunchNextScreen()
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func handlePaymentRequestEvent() throws {
        guard let signedToken = item?["signedtoken"] as? String else { throw "Invalid token" }
        guard let hashData = item?["hashData"] as? String else { throw "Invalid hash data" }
        guard let paymentData = item?["orderObject"] as? String else { throw "Invalid payment data" }
        
        self.showActivityIndicator()
        PaymentServiceManager.paymentVerifySignHashAPI(signedToken: signedToken, hashData: hashData, paymentData: paymentData) { [weak self](response) in
            let signedResponse = Utility.parseJson(apiResponse: response)
            
            if let responseStatus = signedResponse["code"] as? String, responseStatus.lowercased() == WebConstants.success {
                print("success signed data")
                guard let cert = self?.paymentRequestEvent?.merchantCertificateURL else {
                    return
                }
                PaymentServiceManager.validateCertificate(merchantCertURL: cert) { [weak self](response) in
                    let validateCertResponse = Utility.parseJson(apiResponse: response)
                    guard let status = validateCertResponse["code"] as? String, status.lowercased() == WebConstants.success else {
                        DispatchQueue.main.async {
                            (UIApplication.shared.delegate as! AppDelegate).hasPaymentRequested = false
                            self?.hideActivityIndicator()
                            let failedEncodedString = Utility.failureResponse(apiName: "validateCertificate API", apiResponse: validateCertResponse, requestId: self?.paymentRequestEvent?.paymentRequestId)
                            self?.handlerUnauthorisedPayment(encodedPaymentObject: failedEncodedString)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self?.hideActivityIndicator()
                        self?.authWithTouchID()
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as! AppDelegate).hasPaymentRequested = false
                }
                let failedEncodedString = Utility.failureResponse(apiName: "paymentVerifySignHash API", apiResponse: signedResponse, requestId: self?.paymentRequestEvent?.paymentRequestId)
                self?.handlerUnauthorisedPayment(encodedPaymentObject: failedEncodedString)
            }
        }
    }
    
    func handlerUnauthorisedPayment(encodedPaymentObject: String, message: String? = nil)  {
        DispatchQueue.main.async {
            self.hideActivityIndicator()
            let action = UIAlertAction.init(title: "OK", style: .default) { (action) in
                PaymentHandler.shared.respondWith(paymentRequestOrigin: self.paymentRequestEvent?.paymentRequestOrigin ?? "", paymentObject:encodedPaymentObject){ success in }
            }
            self.showAlert(withTitle: "Unauthorised access", andMessage: message ?? "Please try again later", andActions: [action])
        }
    }
    
    //MARK: - Text field delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userName {
            password.becomeFirstResponder()
        }
        else{
            textField.resignFirstResponder()
        }
        
        return true
    }
    //MARK: - Touch ID authentication
    func authWithTouchID() {
        context = LAContext()
        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Log in to your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
                if success {
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [unowned self] in
                        self.validateAndLaunchNextScreen()
                    }
                }
                else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
        }
    }
    //MARK:- Helper method
    /// On tap of login or authorization via touch ID, it validates the internet connectivity and then push the next screen.
    func validateAndLaunchNextScreen() {
        if NetworkReachabilityManager()!.isReachable {
            if (UIApplication.shared.delegate as! AppDelegate).hasPaymentRequested {
                /// Proceed for the PaymentScreen.
                let paymentVC = UIStoryboard.init(name: "PaymentStoryboard", bundle: nil).instantiateViewController(withIdentifier: "paymentViewController") as! PaymentViewController
                paymentVC.paymentRequestEvent = self.paymentRequestEvent
                self.navigationController?.pushViewController(paymentVC, animated: true)
            } else {
                ///Proceed for the Register/Unregister flow.
                let registerVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "registerView") as! RegisterViewController
                self.navigationController?.pushViewController(registerVC, animated: true)
            }
        } else {
            ///No network alert is displayed.
            self.showNoNetworkAlert()
        }
    }
}
