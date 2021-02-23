//
//  PaymentViewController.swift
//  CFITestApp
//
//  Created by Ujjwal Chafle on 18/07/19.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit
import MasterCard

class PaymentViewController: UIViewController {
    
    var paymentRequestEvent: PaymentRequestEvent?
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var merchantId: UILabel!
    @IBOutlet weak var merchantName: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var publicKey :String!
    var merchantCertificate : String!
    var detailsObject = [String: Any]()
    //MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        merchantCertificate = paymentRequestEvent?.merchantCertificateURL
        //        trustMerchantCertificate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let amount = paymentRequestEvent?.total?.value, amount.isEmpty == false {
            amountLabel.text = paymentRequestEvent?.total?.value
        } else {
            amountLabel.text = "100"
        }
        let methodDict = paymentRequestEvent?.methodData![0]
        let data = methodDict?.data
        merchantName.text = data?.merchantName
        merchantId.text = data?.merchantId
        paymentResponseAPI { [weak self](details) in
            if details.keys.count > 0 {
                self?.detailsObject["details"] = details
            }
        }
    }
    
    //MARK: Action Methods
    
    /// Called on tap of confirm button on payment sheet.
    @IBAction func confirmPaymentTapped() {
        if NetworkReachabilityManager()!.isReachable {
            let alert = UIAlertController.init(title: Constant.appName, message: "Do you want to proceed?", preferredStyle: .alert)
            let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
            let proceedAction = UIAlertAction.init(title: "Confirm", style: .default) { (proceed) in
                self.onConfirmAlertTapped()
            }
            alert.addAction(proceedAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            showNoNetworkAlert()
        }
    }
    
    /// Called on tap of confirm of alert.
    func onConfirmAlertTapped() {
        if NetworkReachabilityManager()!.isReachable {
            ///handling confirm payment
            processPayment(encodedPaymentObject: encodedConfirmResponse(), action: "confirm")
        } else {
            showNoNetworkAlert()
        }
    }
    
    /// Called on tap of cancel button on payment sheet.
    @IBAction func onCancel() {
        if NetworkReachabilityManager()!.isReachable {
            ///handling cancel payment
            processPayment(encodedPaymentObject: encodedCancelResponse(), action: "cancel")
        } else {
            showNoNetworkAlert()
        }
    }
}
//MARK:- Merchant certificate and public key
extension PaymentViewController {
    //Mark: Extracting public key from merchant certificate
    /// Performing operations on merchant certificate.
    func trustMerchantCertificate() {
        // remove the header string
        let offset = ("-----BEGIN CERTIFICATE-----").count
        let index = merchantCertificate.index(merchantCertificate.startIndex, offsetBy: offset+1)
        merchantCertificate = merchantCertificate.substring(from: index)
        
        // remove the tail string
        let tailWord = "\n-----END CERTIFICATE-----"
        if let lowerBound = merchantCertificate.range(of: tailWord)?.lowerBound {
            merchantCertificate = merchantCertificate.substring(to: lowerBound)
        }
        
        let certWithoutExtras = merchantCertificate.replacingOccurrences(of: "\n", with: "")
        //decode base64 string to NSData
        let data = NSData(base64Encoded: certWithoutExtras,
                          options:NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            return
        }
        
        let certArray = [ certificate ]
        let policy = SecPolicyCreateBasicX509()
        var optionalTrust: SecTrust?
        let status = SecTrustCreateWithCertificates(certArray as AnyObject, policy, &optionalTrust)
        guard status == errSecSuccess else { return }
        let sectrust = optionalTrust!    // Safe to force unwrap now
        extractPublicKey(trust: sectrust)
    }
    
    /// Extracting public key from SecTrust key
    /// - Parameter trust: Accepts SecTrust key to perform operations in order to extract public key
    func extractPublicKey(trust: SecTrust) {
        // Extract the public key
        let pub_key_leaf = SecTrustCopyPublicKey(trust)
        
        let keychainTag = "X509_TAG"
        
        var publicKeyData : AnyObject?
        var putResult : OSStatus, delResult : OSStatus = noErr
        
        // Params for putting the key first
        let putKeyParams = NSMutableDictionary()
        putKeyParams[kSecClass as String] = kSecClassKey
        putKeyParams[kSecAttrApplicationTag as String] = keychainTag
        putKeyParams[kSecValueRef as String] =  (pub_key_leaf)
        putKeyParams[kSecReturnData as String] = kCFBooleanTrue // Request the key's data to be returned too
        
        // Params for deleting the data
        let delKeyParams = NSMutableDictionary()
        delKeyParams[kSecClass  as String] = kSecClassKey
        delKeyParams[kSecAttrApplicationTag as String] = keychainTag
        delKeyParams[kSecReturnData as String] = kCFBooleanTrue
        
        // Put the key
        putResult = SecItemAdd(putKeyParams, &publicKeyData)
        // Delete the key
        delResult = SecItemDelete(delKeyParams)
        
        if ((putResult != errSecSuccess) || (delResult != errSecSuccess)) {
            publicKeyData = nil;
        }
        
        let keyString = (publicKeyData as! NSData).base64EncodedString(options: NSData.Base64EncodingOptions())
        self.publicKey = keyString
    }
}
//MARK: - Handler for confirm and cancel events
extension PaymentViewController {
    /// Prepares a confirmation paymentResponseEvent in base64 encoded format which will be used by encrypt API.
    ///
    /// - Returns: Base64 encoded payment confirmation string
    func encodedConfirmResponse() -> String {
        let responseEvent=self.createConfirmPaymentResponseObject()
        let paymentDict=self.createConfirmPaymentDictionary(withPaymentObject: responseEvent);
        
        let data: Data = try! JSONSerialization.data(withJSONObject:paymentDict,options: JSONSerialization.WritingOptions.prettyPrinted)
        return data.base64EncodedString()
    }
    
    /// Prepares a cancelled paymentResponseEvent in base64 encoded format which will be used by encrypt API.
    ///
    /// - Returns: Base64 encoded payment cancellation string
    func encodedCancelResponse() -> String {
        let paymentDict=self.createCancelPaymentDictionary();
        let data = Utility.dictionaryToEncodedString(response: paymentDict)
        return data
    }
    
    //MARK: Confirmation PaymentResponse Object
    
    /// Form a paymentResponseObject making using of PaymentRequestEvent's data and other dynamic user data.
    ///
    /// - Returns: Returns a PaymentResponseEvent object
    func createConfirmPaymentResponseObject() -> PaymentResponseEvent {
        let paymentObject = PaymentResponseEvent.init()
        paymentObject.requestId = paymentRequestEvent?.paymentRequestId
        paymentObject.methodName = getmethodName()
        paymentObject.shippingOption = paymentRequestEvent?.shippingOption
        paymentObject.payerName = paymentRequestEvent?.payerName
        paymentObject.payerEmail = paymentRequestEvent?.payerEmail
        paymentObject.payerPhone = paymentRequestEvent?.payerPhone
        ///Shipping address should be as per PaymentRequest Object
        let shippingAddress = PaymentAddress.init()
        shippingAddress.city = paymentRequestEvent?.shippingAddress?.city
        shippingAddress.country = paymentRequestEvent?.shippingAddress?.country
        shippingAddress.dependentLocality = paymentRequestEvent?.shippingAddress?.dependentLocality
        shippingAddress.organization = paymentRequestEvent?.shippingAddress?.organization
        shippingAddress.phone = paymentRequestEvent?.shippingAddress?.phone
        shippingAddress.postalCode = paymentRequestEvent?.shippingAddress?.postalCode
        shippingAddress.region = paymentRequestEvent?.shippingAddress?.region
        shippingAddress.addressLine = paymentRequestEvent?.shippingAddress?.addressLine
        
        paymentObject.shippingAddress = shippingAddress
        
        var responseDetails = self.detailsObject["details"] as! [String: Any]
        responseDetails["id"] = paymentRequestEvent?.paymentRequestId
        if self.paymentRequestEvent?.requestBillingAddress == true {
            //BILLING ADDRESS CAN BE MODIFIED
            let paymentAddress = PaymentAddress.init()
            paymentAddress.city = "Bangalore"
            paymentAddress.country = "India"
            paymentAddress.dependentLocality = "Mini forest"
            paymentAddress.organization = "MasterCard"
            paymentAddress.phone = "0987654321"
            paymentAddress.postalCode = "500165"
            paymentAddress.recipient = ""
            paymentAddress.region = ""
            paymentAddress.addressLine = ["Street 1", "Near new road"]
            
            let city = paymentAddress.city ?? ""
            let country = paymentAddress.country ?? ""
            let dependentLocality = paymentAddress.dependentLocality ?? ""
            let organization = paymentAddress.organization ?? ""
            let phone = paymentAddress.phone ?? ""
            let postalCode = paymentAddress.postalCode ?? ""
            let recipient = paymentAddress.recipient ?? ""
            let region = paymentAddress.region ?? ""
            let addressLine = paymentAddress.addressLine ?? [""]
            
            let billingAddress = ["city": city, "country": country, "dependentLocality": dependentLocality, "organization": organization, "phone": phone, "postalCode": postalCode, "recipient": recipient, "region":region, "addressLine": addressLine] as [String : Any]
            responseDetails["billingAddress"] = billingAddress
            paymentObject.details = responseDetails // self.detailsResponse
        } else {
            paymentObject.details = responseDetails
        }
        return paymentObject
    }
    /// Creates a paymentObject dictionary for payment confirmation.
    ///
    /// - Parameter paymentObject: Accepts a PaymentResponseEvent.
    /// - Returns: PaymentResponseEvent is returned in the form of dictionary
    func createConfirmPaymentDictionary(withPaymentObject paymentObject: PaymentResponseEvent) -> [String: Any]{
        var paymentResponse = [String:Any]()
        paymentResponse["requestId"] = paymentObject.requestId
        paymentResponse["methodName"] = paymentObject.methodName
        paymentResponse["details"] = paymentObject.details
        paymentResponse["shippingOption"] = paymentObject.shippingOption
        paymentResponse["payerName"] = paymentObject.payerName
        paymentResponse["payerEmail"] = paymentObject.payerEmail
        paymentResponse["payerPhone"] = paymentObject.payerPhone
        paymentResponse["isW3C"] = false
        
        let city = paymentObject.shippingAddress?.city ?? ""
        let country = paymentObject.shippingAddress?.country ?? ""
        let loc = paymentObject.shippingAddress?.dependentLocality ?? ""
        let org = paymentObject.shippingAddress?.organization ?? ""
        let phone = paymentObject.shippingAddress?.phone ?? ""
        let pin = paymentObject.shippingAddress?.postalCode ?? ""
        let recpt = paymentObject.shippingAddress?.recipient ?? ""
        let region = paymentObject.shippingAddress?.region ?? ""
        let add = paymentObject.shippingAddress?.addressLine ?? [""]
        paymentResponse["shippingAddress"] = ["city": city, "country": country, "dependentLocality": loc, "organization": org, "phone": phone, "postalCode": pin, "recipient": recpt, "region": region, "addressLine": add]
        return paymentResponse
    }
    //MARK: Cancellation payment object.
    
    /// Creates a paymentObject dictionary for payment cancellation.
    ///
    /// - Returns: Cancellation data is returned in the form of dictionary.
    func createCancelPaymentDictionary() -> [String: Any] {
        var paymentResponse = [String:Any]()
        paymentResponse["requestId"] = paymentRequestEvent?.paymentRequestId
        paymentResponse["error"] = ["message": "The payment request is cancelled by user.", "code": "AHI5009"]
        return paymentResponse
    }
}
//MARK:- Helper methods
extension PaymentViewController {
    /// Fetching method name from PaymentRequestEvent.
    func getmethodName() -> String {
        let methodDict=paymentRequestEvent?.methodData![0]
        let data = methodDict?.data
        let methodName=data?.methodName![0]
        return methodName ?? ""
    }
    /// Handles the processing of payment confirmation and payment cancellation. Navigates the user to merchant site once the request
    /// is processed successfully(confirmation or cancellation).
    ///
    /// - Parameter encodedPaymentObject: Accepts base64 encoded confirmation/cancellation string.
    func processPayment(encodedPaymentObject: String, action: String) {
        if action == "confirm" {
            //            let mockCert = "https://www.uatghokart.com/certificate.pem" // TODO: remove later
            self.showActivityIndicator()
            PaymentServiceManager.encryptAPI(base64EncodedPaymentResponse: encodedPaymentObject, merchantCertURL: self.merchantCertificate) {[weak self] (response) in
                let apiResponse = Utility.parseJson(apiResponse: response)
                
                guard let status = apiResponse["code"] as? String, status.lowercased() == WebConstants.success else {
                    DispatchQueue.main.async {
                        self?.hideActivityIndicator()
                        let action = UIAlertAction.init(title: "OK", style: .default) { (action) in
                            self?.handlerUnauthorisedPayment(apiResponse: apiResponse, apiName: "encryptAPI")
                        }
                        self?.showAlert(withTitle: "Error", andMessage: "Please try again later", andActions: [action])
                    }
                    return
                }
                guard let encryptedPaymentObject = apiResponse["paymentResponse"] as? String else {
                    DispatchQueue.main.async {
                        self?.hideActivityIndicator()
                        let action = UIAlertAction.init(title: "OK", style: .default) { (action) in
                            self?.handlerUnauthorisedPayment(apiResponse: apiResponse, apiName: "encryptAPI")
                        }
                        self?.showAlert(withTitle: "Error", andMessage: apiResponse["message"] as? String ?? "Please try again later",  andActions: [action])
                    }
                    return
                }
                
                PaymentServiceManager.prSignAPI(encryptedPaymentResponse: encryptedPaymentObject) { [weak self](response) in
                    let jwsResponse = Utility.parseJson(apiResponse: response)
                    
                    guard let status = jwsResponse["code"] as? String, status.lowercased() == WebConstants.success else {
                        DispatchQueue.main.async {
                            self?.hideActivityIndicator()
                            let action = UIAlertAction.init(title: "OK", style: .default) { (action) in
                                self?.handlerUnauthorisedPayment(apiResponse: jwsResponse, apiName: "prSignAPI")
                            }
                            self?.showAlert(withTitle: "Error", andMessage: apiResponse["message"] as? String ?? "Please try again later",  andActions: [action])
                        }
                        return
                    }
                    var finalPaymentResponse = [String: Any]()
                    finalPaymentResponse["paymentResponse"] = encryptedPaymentObject
                    finalPaymentResponse["sign"] = jwsResponse["sign"]
                    finalPaymentResponse["message"] = ["code": jwsResponse["code"], "text": jwsResponse["message"]]
                    
                    let encodedPaymentString = Utility.dictionaryToEncodedString(response: finalPaymentResponse)
                    
                    PaymentHandler.shared.respondWith(paymentRequestOrigin: self?.paymentRequestEvent?.paymentRequestOrigin ?? "", paymentObject:encodedPaymentString){
                        success in
                        if(success){
                            //handle success event
                            self?.openLoginView()
                        }else{
                            //handle failure event
                            print("unable to load URL")
                        }
                    }
                    DispatchQueue.main.async {
                        self?.confirmButton.isEnabled = false
                        self?.confirmButton.backgroundColor = .gray
                    }
                }
            }
        } else {
            PaymentHandler.shared.respondWith(paymentRequestOrigin: self.paymentRequestEvent?.paymentRequestOrigin ?? "", paymentObject:encodedPaymentObject){
                success in
                if(success){
                    //handle success event
                    self.openLoginView()
                }else{
                    //handle failure event
                    print("unable to load URL")
                }
            }
            DispatchQueue.main.async {
                self.confirmButton.isEnabled = false
                self.confirmButton.backgroundColor = .gray
            }
            return
        }
    }
    func handlerUnauthorisedPayment(apiResponse: [String:Any], apiName: String)  {
        let encodedPaymentObject = Utility.failureResponse(apiName: apiName, apiResponse: apiResponse, requestId: paymentRequestEvent?.paymentRequestId)
        PaymentHandler.shared.respondWith(paymentRequestOrigin: self.paymentRequestEvent?.paymentRequestOrigin ?? "", paymentObject:encodedPaymentObject){
            success in
            if(success){
                //handle success event
                self.openLoginView()
            }else{
                //handle failure event
                print("unable to load URL")
            }
        }
    }
    /// On successful completion of payment confirmation/cancellation, payment sheet is closed and navigated to login screen.
    func openLoginView() {
        let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginView") as! LoginViewController
        let nav1 = UINavigationController()
        nav1.viewControllers = [controller]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.hasPaymentRequested = false
        appDelegate.window!.rootViewController = nav1
    }
    //MARK: payment response
    
    /// Call paymentResponse API to fetch the "details" which will be a part of paymenrResponse event.
    func paymentResponseAPI(onCompletion paymentResponseDetails:(@escaping([String: Any])-> Void)) {
        PaymentServiceManager.paymentResponseAPI { (response) in
            guard let dictionaryOjb = response as? [String: Any], let finalResponse = dictionaryOjb["details"] as? [String: Any] else {
                paymentResponseDetails([:])
                return
            }
            print("Payment Response API response is \(finalResponse)")
            paymentResponseDetails(finalResponse)
        }
    }
}

