//
//  NCCommunication+E2EE.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 22/05/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
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

    @objc public func markE2EEFolder(fileId: String, delete: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/encrypted/" + fileId + "?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        var typeMethod = ""
        if delete {
            typeMethod = "DELETE"
        } else {
            typeMethod = "PUT"
        }
        let method = HTTPMethod(rawValue: typeMethod)
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
      
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    completionHandler(account, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func lockE2EEFolder(fileId: String, e2eToken: String?, method: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ e2eToken: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/lock/" + fileId + "?format=json"
        var parameters: [String: Any] = [:]
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: method)
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        if e2eToken != nil {
            parameters = ["e2e-token": e2eToken!]
        }
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let e2eToken = json["ocs"]["data"]["e2e-token"].string
                    completionHandler(account, e2eToken, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getE2EEMetadata(fileId: String, e2eToken: String?, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ e2eMetadata: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/meta-data/" + fileId + "?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let e2eMetadata = json["ocs"]["data"]["meta-data"].string
                    completionHandler(account, e2eMetadata, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func putE2EEMetadata(fileId: String, e2eToken: String, e2eMetadata: String?, method: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ metadata: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/meta-data/" + fileId + "?format=json"
        var parameters: [String: Any] = [:]

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        
        let method = HTTPMethod(rawValue: method)
        
        if e2eMetadata != nil {
            parameters = ["metaData": e2eMetadata!, "e2e-token":e2eToken]
        }
       
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode {
                    let metadata = json["ocs"]["data"]["meta-data"].string
                    completionHandler(account, metadata, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    //MARK: -

    @objc public func getE2EECertificate(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ certificate: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
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
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let userId = NCCommunicationCommon.shared.userId
                    let key = json["ocs"]["data"]["public-keys"][userId].stringValue
                    completionHandler(account, key, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getE2EEPrivateKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ privateKey: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
       
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
               if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let key = json["ocs"]["data"]["private-key"].stringValue
                    completionHandler(account, key, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getE2EEPublicKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ publicKey: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/server-key?format=json"
           
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
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let key = json["ocs"]["data"]["public-key"].stringValue
                    completionHandler(account, key, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func signE2EECertificate(certificate: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ certificate: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        let parameters = ["csr": certificate]
        
        sessionManager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode {
                    let key = json["ocs"]["data"]["public-key"].stringValue
                    print(key)
                    completionHandler(account, key, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func storeE2EEPrivateKey(privateKey: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ privateKey: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
        let parameters = ["privateKey": privateKey]
        
        sessionManager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                if let data = response.data {
                    let json = JSON(data)
                    let errorCode = json["ocs"]["meta"]["statuscode"].intValue
                    let errorDescription = json["ocs"]["meta"]["message"].stringValue
                    completionHandler(account, nil, errorCode, errorDescription)
                } else {
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    completionHandler(account, nil, error.errorCode, error.description ?? "")
                }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode {
                    let key = json["ocs"]["data"]["private-key"].stringValue
                    completionHandler(account, key, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func deleteE2EECertificate(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
           
        let method = HTTPMethod(rawValue: "DELETE")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
         
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
    
    @objc public func deleteE2EEPrivateKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
           
        let method = HTTPMethod(rawValue: "DELETE")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
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
}
