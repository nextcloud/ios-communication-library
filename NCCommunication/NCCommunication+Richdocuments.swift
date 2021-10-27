//
//  NCCommunication+Richdocuments.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 18/05/2020.
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

    @objc public func createUrlRichdocuments(fileID: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/richdocuments/api/v1/document?format=json"
        let parameters: [String: Any] = ["fileId": fileID]

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
              
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON(queue: queue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    let url = json["ocs"]["data"]["url"].stringValue
                    completionHandler(account, url, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func getTemplatesRichdocuments(typeTemplate: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ templates: [NCCommunicationRichdocumentsTemplate]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/richdocuments/api/v1/templates/" + typeTemplate + "?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: queue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let data = json["ocs"]["data"].arrayValue
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    var templates: [NCCommunicationRichdocumentsTemplate] = []
                    for templateJSON in data {
                        let template = NCCommunicationRichdocumentsTemplate()
                        
                        template.delete = templateJSON["delete"].stringValue
                        template.templateId = templateJSON["id"].intValue
                        template.ext = templateJSON["extension"].stringValue
                        template.name = templateJSON["name"].stringValue
                        template.preview = templateJSON["preview"].stringValue
                        template.type = templateJSON["type"].stringValue

                        templates.append(template)
                    }
                    completionHandler(account, templates, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func createRichdocuments(path: String, templateId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/richdocuments/api/v1/templates/new?format=json"
        let parameters: [String: Any] = ["path": path, "template": templateId]
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON(queue: queue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    let url = json["ocs"]["data"]["url"].stringValue
                    completionHandler(account, url, 0, "")
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    @objc public func createAssetRichdocuments(path: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account
        let endpoint = "index.php/apps/richdocuments/assets?format=json"
        let parameters: [String: Any] = ["path": path]

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON(queue: queue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let url = json["url"].string
                completionHandler(account, url, 0, "")
            }
        }
    }
}
