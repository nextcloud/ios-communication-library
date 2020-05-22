//
//  NCCommunication+WebDAV.swift
//  NCCommunication
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

    @objc public func createFolder(_ serverUrlFileName: String, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ ocId: String?, _ date: NSDate?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "MKCOL")
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, error.errorCode, error.description)
            case .success( _):
                let ocId = NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields)
                if let dateString = NCCommunicationCommon.shared.findHeader("date", allHeaderFields: response.response?.allHeaderFields) {
                    if let date = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, ocId, date, 0, nil)
                    } else {
                        completionHandler(account, nil, nil, NSURLErrorBadServerResponse, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
                    }
                } else {
                    completionHandler(account, nil, nil, NSURLErrorBadServerResponse, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
                }
            }
        }
    }
     
    @objc public func deleteFileOrFolder(_ serverUrlFileName: String, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "DELETE")
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
     
    @objc public func moveFileOrFolder(serverUrlFileNameSource: String, serverUrlFileNameDestination: String, overwrite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileNameSource) else {
            completionHandler(account, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "MOVE")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(name: "Destination", value: serverUrlFileNameDestination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        if overwrite {
            headers.update(name: "Overwrite", value: "T")
        } else {
            headers.update(name: "Overwrite", value: "F")
        }
         
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
     
    @objc public func copyFileOrFolder(serverUrlFileNameSource: String, serverUrlFileNameDestination: String, overwrite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileNameSource) else {
            completionHandler(account, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "COPY")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(name: "Destination", value: serverUrlFileNameDestination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        if overwrite {
            headers.update(name: "Overwrite", value: "T")
        } else {
            headers.update(name: "Overwrite", value: "F")
        }
         
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
     
    @objc public func readFileOrFolder(serverUrlFileName: String, depth: String, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        var serverUrlFileName = String(serverUrlFileName)
        
        if depth == "1" && serverUrlFileName.last != "/" { serverUrlFileName = serverUrlFileName + "/" }
        if depth == "0" && serverUrlFileName.last == "/" { serverUrlFileName = String(serverUrlFileName.remove(at: serverUrlFileName.index(before: serverUrlFileName.endIndex))) }
        
        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "PROPFIND")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))
        headers.update(name: "Depth", value: depth)

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NCDataFileXML().requestBodyFile.data(using: .utf8)
        } catch {
            completionHandler(account, nil, error._code, error.localizedDescription)
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let files = NCDataFileXML().convertDataFile(data: data, showHiddenFiles: showHiddenFiles)
                    completionHandler(account, files, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
     
    @objc public func searchLiteral(serverUrl: String, depth: String, literal: String, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, user: String, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let href = NCCommunicationCommon.shared.encodeString("/files/" + user ) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        guard let literal = NCCommunicationCommon.shared.encodeString(literal) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_literal_", value: "Invalid search string", comment: ""))
            return
        }
        
        let requestBody = String(format: NCDataFileXML().requestBodySearchFileName, href, depth, "%"+literal+"%")
        let httpBody = requestBody.data(using: .utf8)!
     
        search(serverUrl: serverUrl, httpBody: httpBody, showHiddenFiles: showHiddenFiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, account: account) { (account, files, erroCode, errorDescription) in
            completionHandler(account,files,erroCode,errorDescription)
        }
    }
    
    @objc public func searchMedia(lteDateLastModified: Date, gteDateLastModified: Date, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, user: String, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
            
        let account = NCCommunicationCommon.shared.account
        
        guard let href = NCCommunicationCommon.shared.encodeString("/files/" + user ) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        guard let lteDateLastModifiedString = NCCommunicationCommon.shared.convertDate(lteDateLastModified, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ") else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
            return
        }
        guard let gteDateLastModifiedString = NCCommunicationCommon.shared.convertDate(gteDateLastModified, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ") else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
            return
        }
         
        let requestBody = String(format: NCDataFileXML().requestBodySearchMedia, href, lteDateLastModifiedString, gteDateLastModifiedString)
        let httpBody = requestBody.data(using: .utf8)!
        
        search(serverUrl: NCCommunicationCommon.shared.url, httpBody: httpBody, showHiddenFiles: showHiddenFiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, account: account) { (account, files, erroCode, errorDescription) in
            completionHandler(account,files,erroCode,errorDescription)
        }
    }
     
    private func search(serverUrl: String, httpBody: Data, showHiddenFiles: Bool, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrl + "/" + NCCommunicationCommon.shared.davRoot) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "SEARCH")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("text/xml"))
         
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = httpBody
        } catch {
            completionHandler(account, nil, error._code, error.localizedDescription)
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let files = NCDataFileXML().convertDataFile(data: data, showHiddenFiles: showHiddenFiles)
                    completionHandler(account, files, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
     
    @objc public func setFavorite(fileName: String, favorite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        let serverUrlFileName = NCCommunicationCommon.shared.url + "/" + NCCommunicationCommon.shared.davRoot + "/files/" + NCCommunicationCommon.shared.userId + "/" + fileName
        
        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "PROPPATCH")
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
         
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let body = NSString.init(format: NCDataFileXML().requestBodyFileSetFavorite as NSString, (favorite ? 1 : 0)) as String
            urlRequest.httpBody = body.data(using: .utf8)
        } catch {
            completionHandler(account, error._code, error.localizedDescription)
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
     
    @objc public func listingFavorites(showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        let serverUrlFileName = NCCommunicationCommon.shared.url + "/" + NCCommunicationCommon.shared.davRoot + "/files/" + NCCommunicationCommon.shared.userId
        
        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
         
        let method = HTTPMethod(rawValue: "REPORT")
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
         
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NCDataFileXML().requestBodyFileListingFavorites.data(using: .utf8)
        } catch {
            completionHandler(account, nil, error._code, error.localizedDescription)
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let files = NCDataFileXML().convertDataFile(data: data, showHiddenFiles: showHiddenFiles)
                    completionHandler(account, files, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
    
    @objc public func listingTrash(showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String:String]? = nil, completionHandler: @escaping (_ account: String, _ items: [NCCommunicationTrash]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let serverUrlFileName = NCCommunicationCommon.shared.url + "/" + NCCommunicationCommon.shared.davRoot + "/trashbin/" + NCCommunicationCommon.shared.userId + "/trash/"
            
        guard let url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "PROPFIND")
             
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))
        headers.update(name: "Depth", value: "1")

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NCDataFileXML().requestBodyTrash.data(using: .utf8)
        } catch {
            completionHandler(account, nil, error._code, error.localizedDescription)
            return
        }
             
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let items = NCDataFileXML().convertDataTrash(data: data, showHiddenFiles: showHiddenFiles)
                    completionHandler(account, items, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
}
