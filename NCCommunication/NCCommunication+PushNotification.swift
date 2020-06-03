//
//  NCCommunication+PushNotification.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 22/05/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import Alamofire
import SwiftyJSON

extension NCCommunication {

    @objc public func subscribingPushNotification(serverUrl: String, account: String, user: String, password: String, pushTokenHash: String, devicePublicKey: String, proxyServerUrl: String, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ deviceIdentifier: String?, _ signature: String?, _ publicKey: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let endpoint = "ocs/v2.php/apps/notifications/api/v2/push?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let parameters = [
            "pushTokenHash": pushTokenHash,
            "devicePublicKey": devicePublicKey,
            "proxyServer": proxyServerUrl,
        ]
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(user: user, password: password, appendHeaders: addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let deviceIdentifier = json["ocs"]["data"]["deviceIdentifier"].stringValue
                    let signature = json["ocs"]["data"]["signature"].stringValue
                    let publicKey = json["ocs"]["data"]["publicKey"].stringValue
                    completionHandler(account, deviceIdentifier, signature, publicKey, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, nil, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func unsubscribingPushNotification(serverUrl: String, account: String, user: String, password: String, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let endpoint = "ocs/v2.php/apps/notifications/api/v2/push"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "DELETE")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(user: user, password: password, appendHeaders: addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success( _):
                completionHandler(account, 0, "")
            }
        }
    }
    
    @objc public func subscribingPushProxy(proxyServerUrl: String, pushToken: String, deviceIdentifier: String, signature: String, publicKey: String, userAgent: String, completionHandler: @escaping (_ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let endpoint = "devices?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: proxyServerUrl, endpoint: endpoint) else {
            completionHandler(NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let parameters = [
            "pushToken": pushToken,
            "deviceIdentifier": deviceIdentifier,
            "deviceIdentifierSignature": signature,
            "userPublicKey": publicKey
        ]
        
        let headers = HTTPHeaders.init(arrayLiteral: .userAgent(userAgent))
                
        sessionManager.request(url, method: method, parameters:parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(error.errorCode, error.description ?? "")
            case .success( _):
                completionHandler(0, "")
            }
        }
    }
    
    @objc public func unsubscribingPushProxy(proxyServerUrl: String, deviceIdentifier: String, signature: String, publicKey: String, userAgent: String, completionHandler: @escaping (_ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let endpoint = "devices"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: proxyServerUrl, endpoint: endpoint) else {
            completionHandler(NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "DELETE")
        
        let parameters = [
            "deviceIdentifier": deviceIdentifier,
            "deviceIdentifierSignature": signature,
            "userPublicKey": publicKey
        ]
        
        let headers = HTTPHeaders.init(arrayLiteral: .userAgent(userAgent))
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(error.errorCode, error.description ?? "")
            case .success( _):
                completionHandler(0, "")
            }
        }
    }
}

