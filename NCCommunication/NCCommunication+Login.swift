//
//  NCCommunication+LoginFlowV2.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 07/05/2020.
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
        
    //MARK: - App Password
    
    @objc public func getAppPassword(serverUrl: String, username: String, password: String, customUserAgent: String? = nil, completionHandler: @escaping (_ token: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let endpoint = "/ocs/v2.php/core/getapppassword"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        var headers: HTTPHeaders = [.authorization(username: username, password: password)]
        if customUserAgent != nil {
            headers.update(.userAgent(customUserAgent!))
        } else if let userAgent = NCCommunicationCommon.shared.userAgent {
            headers.update(.userAgent(userAgent))
        }
        headers.update(name: "OCS-APIRequest", value: "true")
               
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: HTTPMethod(rawValue: "GET"), headers: headers)
        } catch {
            completionHandler(nil, error._code, error.localizedDescription)
            return
        }

        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response { (response) in

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(nil, error.errorCode, error.description ?? "")
            case .success(let data):
                if let data = data {
                    let apppassword = NCDataFileXML().convertDataAppPassword(data: data)
                    completionHandler(apppassword, 0, "")
                } else {
                    completionHandler(nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
    
    //MARK: - Login Flow V2
    
    @objc public func getLoginFlowV2(serverUrl: String, completionHandler: @escaping (_ token: String?, _ endpoint: String? , _ login: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let endpoint = "index.php/login/v2"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(nil, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(nil, nil, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
               
                let token = json["poll"]["token"].string
                let endpoint = json["poll"]["endpoint"].string
                let login = json["login"].string
                
                completionHandler(token, endpoint, login, 0, "")
            }
        }
    }
    
    @objc public func getLoginFlowV2Poll(token: String, endpoint: String, completionHandler: @escaping (_ server: String?, _ loginName: String? , _ appPassword: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let serverUrl = endpoint + "?token=" + token
        guard let url = NCCommunicationCommon.shared.StringToUrl(serverUrl) else {
            completionHandler(nil, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }

        let method = HTTPMethod(rawValue: "POST")
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(nil, nil, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
               
                let server = json["server"].string
                let loginName = json["loginName"].string
                let appPassword = json["appPassword"].string
                
                completionHandler(server, loginName, appPassword, 0, "")
            }
        }
    }
}
