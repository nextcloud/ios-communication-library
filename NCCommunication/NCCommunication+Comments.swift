//
//  NCCommunication+Comments.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 21/05/2020.
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

extension NCCommunication {

    @objc public func getComments(fileId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ items: [NCCommunicationComments]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let serverUrlEndpoint = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/comments/files/" + fileId
            
        guard let url = serverUrlEndpoint.encodedToUrl else {
            queue.async { completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "PROPFIND")
             
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NCDataFileXML().requestBodyComments.data(using: .utf8)
        } catch {
            queue.async { completionHandler(account, nil, error._code, error.localizedDescription) }
            return
        }
          
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, nil, error.errorCode, error.description ?? "") }
            case .success( _):
                if let data = response.data {
                    let items = NCDataFileXML().convertDataComments(data: data)
                    queue.async { completionHandler(account, items, 0, "") }
                } else {
                    queue.async { completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: "")) }
                }
            }
        }
    }

    @objc public func putComments(fileId: String, message: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        let serverUrlEndpoint = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/comments/files/" + fileId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            queue.async { completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/json"))

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let parameters = "{\"actorType\":\"users\",\"verb\":\"comment\",\"message\":\"" + message + "\"}"
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            queue.async { completionHandler(account, error._code, error.localizedDescription) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, error.errorCode, error.description ?? "") }
            case .success( _):
                queue.async { completionHandler(account, 0, "") }
            }
        }
    }
    
    @objc public func updateComments(fileId: String, messageId: String, message: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        let serverUrlEndpoint = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/comments/files/" + fileId + "/" + messageId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            queue.async { completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "PROPPATCH")
        
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let parameters = String(format: NCDataFileXML().requestBodyCommentsUpdate, message)
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            queue.async { completionHandler(account, error._code, error.localizedDescription) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, error.errorCode, error.description ?? "") }
            case .success( _):
                queue.async { completionHandler(account, 0, "") }
            }
        }
    }
    
    @objc public func deleteComments(fileId: String, messageId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        let serverUrlEndpoint = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/comments/files/" + fileId + "/" + messageId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            queue.async { completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "DELETE")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, error.errorCode, error.description ?? "") }
            case .success( _):
                queue.async { completionHandler(account, 0, "") }
            }
        }
    }
    
    @objc public func markAsReadComments(fileId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        let serverUrlEndpoint = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/comments/files/" + fileId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            queue.async { completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "PROPPATCH")
        
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let parameters = String(format: NCDataFileXML().requestBodyCommentsMarkAsRead)
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            queue.async { completionHandler(account, error._code, error.localizedDescription) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, error.errorCode, error.description ?? "") }
            case .success( _):
                queue.async { completionHandler(account, 0, "") }
            }
        }
    }
}
