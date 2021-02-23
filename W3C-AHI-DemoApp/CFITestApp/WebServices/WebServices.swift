//
//  WebServices.swift
//  CFITestApp
//
//  Created by Ujjwal Chafle on 13/01/20.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit

class WebServices {
    /// Creating a completion handler to receive results from server
    ///
    /// - Parameters:
    ///   - service: a URL identifying the resource we want
    ///   - paramDictionary: optional parameters for the server in the form of HTTP body
    ///   - method: HTTP method
    ///   - successBlock: completion handler for success
    ///   - failureBlock: completion handler for failure
    static func fetchResponse(withServiceName service: String, paramDictionary:Any, method:String, onSuccess successBlock:@escaping((Any)-> Void), onFailure failureBlock:@escaping((String)->Void)) {
        guard let serviceUrl = URL(string: service) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let paramDictionary = paramDictionary as? [String: Any] {
            guard let httpBody = try? JSONSerialization.data(withJSONObject: paramDictionary, options: []) else { return }
            request.httpBody = httpBody
        }
        
        if let paramString = paramDictionary as? String {
            request.httpBody = paramString.data(using: String.Encoding.utf8)
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let _ = response { }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    successBlock(json)
                } catch {
                    failureBlock(error.localizedDescription)
                }
            } else {
                failureBlock(error!.localizedDescription)
            }
        }.resume()
    }
    /// Creating a completion handler to receive results from server
    ///
    /// - Parameters:
    ///   - service: a URL identifying the resource we want
    ///   - httpHeader: header for the server
    ///   - paramDictionary: optional parameters for the server in the form of HTTP body
    ///   - method: HTTP method
    ///   - successBlock: completion handler for success
    ///   - failureBlock: completion handler for failure
    static func fetchResponseWithHeader(withServiceName service: String, httpHeader:[String:String],paramDictionary:[String:String], method:String, onSuccess successBlock:@escaping((Any)-> Void), onFailure failureBlock:@escaping((String)->Void)) {
        guard let serviceUrl = URL(string: service) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.allHTTPHeaderFields = httpHeader
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: paramDictionary, options: []) else { return }
        request.httpBody = httpBody
        
        print("request is: \(request.description)")
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let _ = response { }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    successBlock(json)
                } catch {
                    failureBlock(error.localizedDescription)
                }
            } else {
                failureBlock(error!.localizedDescription)
            }
        }.resume()
    }
    
}
