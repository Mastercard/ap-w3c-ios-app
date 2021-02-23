//
//  MCConstant.swift
//  MCApp
//
//  Created by Ujjwal Chafle on 5/20/19.
//  Copyright © 2021 Mastercard. All rights reserved.

import Foundation

public struct Constant {
    
    static let walletID = "195b258f4565da4e79f3e21f75500392ac1d28c9c60e523de7a39db36aa674a6"
    static let paymentType = "mcpba"
    static let baseURL = "http://www.qaghobank.com:9091"
    static let environment = "qa"
    
    static let paymentResponseURL = "\(baseURL)/paymentresponse"
    static let encryptURL = "\(baseURL)/encrypt"
    static let verifySignInHashURL = "\(baseURL)/verifysignhash"
    static let prsignURL = "\(baseURL)/prsign"
    static let validateCertificate = "\(baseURL)/validatecertificate"
    
    static let appName = "GhoBank"
}

