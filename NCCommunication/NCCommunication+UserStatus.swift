//
//  NCCommunication+UserStatus.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 22/11/20.
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
    
    @objc public func getUserStatus(userId: String? = nil, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ status: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
    
        let account = NCCommunicationCommon.shared.account
        var endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status?format=json"
        if let userId = userId {
            endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status/" + userId + "?format=json"
        }
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    
                    completionHandler(account, nil, 0, "")
                    
                } else {
                    
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func setUserStatus(status: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status/status?format=json"

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "PUT")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        let parameters = [
            "statusType": String(status)
        ]
                
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func setCustomMessagePredefined(messageId: String, clearAt: Int, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status//message/predefined?format=json"

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "PUT")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        var parameters = [
            "messageId": String(messageId)
        ]
        if clearAt > 0 {
            parameters["clearAt"] = String(clearAt)
        }
                
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func setCustomMessageUserDefined(statusIcon: String?, message: String, clearAt: Int, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status//message/custom?format=json"

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "PUT")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        var parameters = [
            "message": String(message)
        ]
        if statusIcon != nil {
            parameters["statusIcon"] = statusIcon
        }
        if clearAt > 0 {
            parameters["clearAt"] = String(clearAt)
        }
                
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func clearMessage(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/user_status/message?format=json"

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "DELETE")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getUserStatusPredefinedStatuses(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ status: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
    
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/predefined_statuses?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    
                    completionHandler(account, nil, 0, "")
                    
                } else {
                    
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getUserStatusRetrieveStatuses(limit: Int, offset: Int, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ status: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
    
        let account = NCCommunicationCommon.shared.account
        let endpoint = "/ocs/v2.php/apps/user_status/api/v1/predefined_statuses?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        let parameters = [
            "limit": String(limit),
            "offset": String(offset)
        ]
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    
                    completionHandler(account, nil, 0, "")
                    
                } else {
                    
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
}
