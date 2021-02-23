//
//  Utility.swift
//  CFITestApp
//
//  Created by Ujjwal Chafle on 02/03/20.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit

class Utility: NSObject {
    
    static func dictionaryToEncodedString(response: [String: Any]) -> String {
        let data: Data = try! JSONSerialization.data(withJSONObject:response,options: JSONSerialization.WritingOptions.prettyPrinted)
        return data.base64EncodedString()
    }
    
    static func encodedStringToDictionary(base64encodedString: String) -> [String:Any]? {
        guard let data = Data(base64Encoded: base64encodedString) else {
            return ["error": "invalid encoded string"]
        }
        do {
            ///constructing dictionary from JSON data
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            return dictionary
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
            return ["error": error.localizedDescription, "message": "unable to parse"]
        }
    }
    
    static func parseJson(apiResponse: Any) -> [String: Any] {
        guard let validResponse = apiResponse as? [String: Any] else {
            let response = ["Error": "Please try again."]
            return response
        }
        return validResponse
    }
    
    static func failureResponse(apiName: String, apiResponse: [String: Any], requestId: String? = nil) -> String {
        var failureDictionary = [String: Any]()
        let apiMessage = apiResponse["message"] as? String ?? "API failed to respond"
        if requestId != nil {
            failureDictionary["requestId"] = requestId
        }
        failureDictionary["error"] = ["code": apiResponse["code"] as? String ?? "AHI5010", "message": "\(apiName)- \(apiMessage))"]
        return Utility.dictionaryToEncodedString(response: failureDictionary)
    }
}
