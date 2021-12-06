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

    @objc public func markE2EEFolder(fileId: String, delete: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/encrypted/" + fileId + "?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, .urlError) }
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
      
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    queue.async { completionHandler(account, .success) }
                } else {
                    queue.async { completionHandler(account, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func lockE2EEFolder(fileId: String, e2eToken: String?, method: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ e2eToken: String?, _ error: NCCError) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/lock/" + fileId + "?format=json"
        var parameters: [String: Any] = [:]
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }
        
        let method = HTTPMethod(rawValue: method)
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        if e2eToken != nil {
            parameters = ["e2e-token": e2eToken!]
        }
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    let e2eToken = json["ocs"]["data"]["e2e-token"].string
                    queue.async { completionHandler(account, e2eToken, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func getE2EEMetadata(fileId: String, e2eToken: String?, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ e2eMetadata: String?, _ error: NCCError) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/meta-data/" + fileId + "?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    let e2eMetadata = json["ocs"]["data"]["meta-data"].string
                    queue.async { completionHandler(account, e2eMetadata, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func putE2EEMetadata(fileId: String, e2eToken: String, e2eMetadata: String?, method: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ metadata: String?, _ error: NCCError) -> Void) {
                            
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/meta-data/" + fileId + "?format=json"
        var parameters: [String: Any] = [:]

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
        
        let method = HTTPMethod(rawValue: method)
        
        if e2eMetadata != nil {
            parameters = ["metaData": e2eMetadata!, "e2e-token":e2eToken]
        }
       
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode {
                    let metadata = json["ocs"]["data"]["meta-data"].string
                    queue.async { completionHandler(account, metadata, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    //MARK: -

    @objc public func getE2EECertificate(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ certificate: String?, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }
           
        let method = HTTPMethod(rawValue: "GET")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    let userId = NCCommunicationCommon.shared.userId
                    let key = json["ocs"]["data"]["public-keys"][userId].stringValue
                    queue.async { completionHandler(account, key, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func getE2EEPrivateKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ privateKey: String?, _ error: NCCError) -> Void) {
                           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
       
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }
       
        let method = HTTPMethod(rawValue: "GET")
       
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
       
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                    let error = NCCError(error: error, afResponse: response)
                    queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    let key = json["ocs"]["data"]["private-key"].stringValue
                    queue.async { completionHandler(account, key, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func getE2EEPublicKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ publicKey: String?, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/server-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }
           
        let method = HTTPMethod(rawValue: "GET")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode  {
                    let key = json["ocs"]["data"]["public-key"].stringValue
                    queue.async { completionHandler(account, key, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func signE2EECertificate(certificate: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ certificate: String?, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        let parameters = ["csr": certificate]
        
        sessionManager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode {
                    let key = json["ocs"]["data"]["public-key"].stringValue
                    print(key)
                    queue.async { completionHandler(account, key, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func storeE2EEPrivateKey(privateKey: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ privateKey: String?, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, .urlError) }
            return
        }

        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
        let parameters = ["privateKey": privateKey]
        
        sessionManager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, error) }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
                if 200..<300 ~= statusCode {
                    let key = json["ocs"]["data"]["private-key"].stringValue
                    queue.async { completionHandler(account, key, .success) }
                } else {
                    queue.async { completionHandler(account, nil, NCCError(rootJson: json)) }
                }
            }
        }
    }
    
    @objc public func deleteE2EECertificate(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/public-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, .urlError) }
            return
        }
           
        let method = HTTPMethod(rawValue: "DELETE")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
         
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, error) }
            case .success( _):
                queue.async { completionHandler(account, .success) }
            }
        }
    }
    
    @objc public func deleteE2EEPrivateKey(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
                               
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/end_to_end_encryption/api/v1/private-key?format=json"
           
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            queue.async { completionHandler(account, .urlError) }
            return
        }
           
        let method = HTTPMethod(rawValue: "DELETE")
           
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
           
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, error) }
            case .success( _):
                queue.async { completionHandler(account, .success) }
            }
        }
    }
}
