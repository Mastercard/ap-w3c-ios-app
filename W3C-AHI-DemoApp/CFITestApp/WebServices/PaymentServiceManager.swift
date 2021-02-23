//
//  PaymentServiceManager.swift
//  CFITestApp
//
//  Created by Ujjwal Chafle on 12/02/20.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit

class PaymentServiceManager: NSObject {
    /// Calling the paymentVerifySignHashAPI API to fetch verification status.
    ///
    /// - Parameters:
    ///   - signedToken: Takes the signedToken in string format.
    ///   - hashData: Takes the hashData in string format.
    ///   - paymentData: Takes the paymentData in string format.
    ///   - onCompletion: callback handler to receive the api response
    static func paymentVerifySignHashAPI(signedToken: String, hashData: String, paymentData: String, completionHander onCompletion:@escaping((Any)->Void)) {
        let url = String(format: Constant.verifySignInHashURL)
        let parameterDictionary = ["paymentRequest": paymentData, "hashData": hashData]
        let httpMethod = "POST"
        let httpHeader = [
            "Content-Type": "application/json",
            "X-JWS-Signature": signedToken
        ] as [String : String]
        
        WebServices.fetchResponseWithHeader(withServiceName: url, httpHeader: httpHeader, paramDictionary: parameterDictionary, method: httpMethod, onSuccess: { (response) in
            print("verifysignhash \(response)")
            onCompletion(response)
        }) { (error) in
            print(error)
            onCompletion(error)
        }
    }
    
    /// Calling the encrypt API to fetch encrypted paymentResponse and status.
    ///
    /// - Parameters:
    ///   - base64EncodedPaymentResponse: Takes the base64 encoded paymentResponse of cancel or confirmed payment in string format.
    ///   - merchantCertificate: Takes the merchantCertificate needed for cancel or confirmed payment in string format.
    ///   - onCompletion: callback handler to receive the api response
    static func encryptAPI(base64EncodedPaymentResponse: String, merchantCertURL: String, completionHander onCompletion:@escaping((Any)->Void)) {
        let url = String(format: Constant.encryptURL)
        
        let parameterDictionary = ["merchantCertificateURL": merchantCertURL, "paymentResponse": base64EncodedPaymentResponse]
        let httpMethod = "POST"
        WebServices.fetchResponse(withServiceName: url, paramDictionary: parameterDictionary as [String : Any], method: httpMethod, onSuccess: { (response) in
            print("encryptAPI \(response)")
            onCompletion(response)
        }) { (error) in
            print("encryptAPI \(error)")
            onCompletion(error)
        }
    }
    
    static func paymentResponseAPI(completionHander onCompletion:@escaping((Any)->Void)) {
        let url = String(format: Constant.paymentResponseURL)
        let parameterDictionary = ["paymentType" : Constant.paymentType, "walletID" : Constant.walletID]
        let httpMethod = "POST"
        WebServices.fetchResponse(withServiceName: url, paramDictionary: parameterDictionary, method: httpMethod, onSuccess: { (response) in
            print("paymentResponseAPI \(response)")
            onCompletion(response)
        }) { (error) in
            print("paymentResponseAPI \(error)")
            onCompletion(error)
        }
    }
    
    static func validateCertificate(merchantCertURL: String, completionHandler onCompletion: @escaping((Any)-> Void)) {
        let url = Constant.validateCertificate
        let paramDictionary =  ["merchantCertificateURL": merchantCertURL, "walletId": Constant.walletID, "paymentType": Constant.paymentType]
        WebServices.fetchResponse(withServiceName: url, paramDictionary: paramDictionary, method: "POST", onSuccess: { (response) in
            print("validateCertificate \(response)")
            onCompletion(response)
        }) { (error) in
            print("validateCertificate \(error)")
            onCompletion(error)
        }
    }
    
    static func prSignAPI(encryptedPaymentResponse: String, completionHandler onCompletion: @escaping((Any)-> Void)) {
        let url = Constant.prsignURL
        let paramDictionary = encryptedPaymentResponse
        WebServices.fetchResponse(withServiceName: url, paramDictionary: paramDictionary, method: "POST", onSuccess: { (response) in
            print("prSignAPI \(response)")
            onCompletion(response)
        }) { (error) in
            print("prSignAPI \(error)")
            onCompletion(error)
        }
    }
}
