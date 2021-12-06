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

    @objc public func createFolder(_ serverUrlFileName: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ ocId: String?, _ date: NSDate?, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = serverUrlFileName.encodedToUrl else {
            queue.async { completionHandler(account, nil, nil, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "MKCOL")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, nil, nil, error) }
            case .success( _):
                let ocId = NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields)
                if let dateString = NCCommunicationCommon.shared.findHeader("date", allHeaderFields: response.response?.allHeaderFields) {
                    if let date = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        queue.async { completionHandler(account, ocId, date, .success) }
                    } else {
                        queue.async { completionHandler(account, nil, nil, .invalidDate) }
                    }
                } else {
                    queue.async { completionHandler(account, nil, nil, .invalidDate) }
                }
            }
        }
    }
     
    @objc public func deleteFileOrFolder(_ serverUrlFileName: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = serverUrlFileName.encodedToUrl else {
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
     
    @objc public func moveFileOrFolder(serverUrlFileNameSource: String, serverUrlFileNameDestination: String, overwrite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = serverUrlFileNameSource.encodedToUrl else {
            queue.async { completionHandler(account, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "MOVE")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(name: "Destination", value: serverUrlFileNameDestination.urlEncoded ?? "")
        if overwrite {
            headers.update(name: "Overwrite", value: "T")
        } else {
            headers.update(name: "Overwrite", value: "F")
        }
         
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
     
    @objc public func copyFileOrFolder(serverUrlFileNameSource: String, serverUrlFileNameDestination: String, overwrite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account

        guard let url = serverUrlFileNameSource.encodedToUrl else {
            queue.async { completionHandler(account, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "COPY")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(name: "Destination", value: serverUrlFileNameDestination.urlEncoded ?? "")
        if overwrite {
            headers.update(name: "Overwrite", value: "T")
        } else {
            headers.update(name: "Overwrite", value: "F")
        }
         
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
     
    @objc public func readFileOrFolder(serverUrlFileName: String, depth: String, showHiddenFiles: Bool = true, requestBody: Data? = nil, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ responseData: Data?, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        var files: [NCCommunicationFile] = []
        var serverUrlFileName = serverUrlFileName
        
        if depth == "1" && serverUrlFileName.last != "/" { serverUrlFileName = serverUrlFileName + "/" }
        if depth == "0" && serverUrlFileName.last == "/" { serverUrlFileName = String(serverUrlFileName.remove(at: serverUrlFileName.index(before: serverUrlFileName.endIndex))) }
        
        guard let url = serverUrlFileName.encodedToUrl else {
            queue.async { completionHandler(account, files, nil, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "PROPFIND")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))
        headers.update(name: "Depth", value: depth)

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            if requestBody != nil {
                urlRequest.httpBody = requestBody!
            } else {
                urlRequest.httpBody = NCDataFileXML().requestBodyFile.data(using: .utf8)
            }
        } catch {
            queue.async { completionHandler(account, files, nil, NCCError(error: error)) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, files, nil, error) }
            case .success( _):
                if let data = response.data {
                    files = NCDataFileXML().convertDataFile(data: data, user: NCCommunicationCommon.shared.user, userId: NCCommunicationCommon.shared.userId, showHiddenFiles: showHiddenFiles)
                    queue.async { completionHandler(account, files, data, .success) }
                } else {
                    queue.async { completionHandler(account, files, nil, .xmlError) }
                }
            }
        }
    }
     
    @objc public func searchBodyRequest(serverUrl: String, requestBody: String, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, timeout: TimeInterval = 60, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        let httpBody = requestBody.data(using: .utf8)!
     
        search(serverUrl: serverUrl, httpBody: httpBody, showHiddenFiles: showHiddenFiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, account: account, timeout: timeout, queue: queue) { (account, files, error) in
            queue.async { completionHandler(account, files, error) }
        }
    }
    
    @objc public func searchLiteral(serverUrl: String, depth: String, literal: String, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, timeout: TimeInterval = 60, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ error: NCCError) -> Void) {
        let account = NCCommunicationCommon.shared.account

        guard let href = ("/files/" + NCCommunicationCommon.shared.userId).urlEncoded else {
            queue.async { completionHandler(account, [], .urlError) }
            return
        }
        
        let requestBody = String(format: NCDataFileXML().requestBodySearchFileName, href, depth, "%"+literal+"%")
        let httpBody = requestBody.data(using: .utf8)!
     
        search(serverUrl: serverUrl, httpBody: httpBody, showHiddenFiles: showHiddenFiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, account: account, timeout: timeout, queue: queue) { (account, files, error) in
            queue.async { completionHandler(account, files, error) }
        }
    }
    
    @objc public func searchMedia(path: String = "", lessDate: Any, greaterDate: Any, elementDate: String, limit: Int, showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, timeout: TimeInterval = 60, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ error: NCCError) -> Void) {
            
        let account = NCCommunicationCommon.shared.account
        let files: [NCCommunicationFile] = []
        var greaterDateString: String?, lessDateString: String?
        
        guard let href = ("/files/" + NCCommunicationCommon.shared.userId + path).urlEncoded else {
            queue.async { completionHandler(account, files, .urlError) }
            return
        }
        
        if lessDate is Date || lessDate is NSDate {
            lessDateString = NCCommunicationCommon.shared.convertDate(lessDate as! Date, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        } else if lessDate is Int {
            lessDateString = String(lessDate as! Int)
        }
        
        if greaterDate is Date || greaterDate is NSDate {
            greaterDateString = NCCommunicationCommon.shared.convertDate(greaterDate as! Date, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        } else if greaterDate is Int {
            greaterDateString = String(greaterDate as! Int)
        }
        
        if lessDateString == nil || greaterDateString == nil {
            queue.async { completionHandler(account, files, .invalidDate) }
            return
        }
        
        var requestBody = ""
        if limit > 0 {
            requestBody = String(format: NCDataFileXML().requestBodySearchMediaWithLimit, href, elementDate, elementDate, lessDateString!, elementDate, greaterDateString!, String(limit))
        } else {
            requestBody = String(format: NCDataFileXML().requestBodySearchMedia, href, elementDate, elementDate, lessDateString!, elementDate, greaterDateString!)
        }
        
        let httpBody = requestBody.data(using: .utf8)!
        
        search(serverUrl: NCCommunicationCommon.shared.urlBase, httpBody: httpBody, showHiddenFiles: showHiddenFiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, account: account, timeout: timeout, queue: queue) { (account, files, error) in
            queue.async { completionHandler(account, files, error) }
        }
    }
     
    private func search(serverUrl: String, httpBody: Data, showHiddenFiles: Bool, customUserAgent: String?, addCustomHeaders: [String: String]?, account: String, timeout: TimeInterval, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ error: NCCError) -> Void) {
         
        var files: [NCCommunicationFile] = []
        
        guard let url = (serverUrl + "/" + NCCommunicationCommon.shared.webDav).encodedToUrl else {
            queue.async { completionHandler(account, files, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "SEARCH")
         
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("text/xml"))
         
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = httpBody
            urlRequest.timeoutInterval = timeout
        } catch {
            queue.async { completionHandler(account, files, NCCError(error: error)) }
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, files, error) }
            case .success( _):
                if let data = response.data {
                    files = NCDataFileXML().convertDataFile(data: data, user: NCCommunicationCommon.shared.user, userId: NCCommunicationCommon.shared.userId, showHiddenFiles: showHiddenFiles)
                    queue.async { completionHandler(account, files, .success) }
                } else {
                    queue.async { completionHandler(account, files, .xmlError) }
                }
            }
        }
    }
     
    @objc public func setFavorite(fileName: String, favorite: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        let serverUrlFileName = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/files/" + NCCommunicationCommon.shared.userId + "/" + fileName
        
        guard let url = serverUrlFileName.encodedToUrl else {
            queue.async { completionHandler(account, .urlError) }
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
            queue.async { completionHandler(account, NCCError(error: error)) }
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
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
     
    @objc public func listingFavorites(showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ files: [NCCommunicationFile], _ error: NCCError) -> Void) {
         
        let account = NCCommunicationCommon.shared.account
        let serverUrlFileName = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/files/" + NCCommunicationCommon.shared.userId
        var files: [NCCommunicationFile] = []

        guard let url = serverUrlFileName.encodedToUrl else {
            queue.async { completionHandler(account, files, .urlError) }
            return
        }
         
        let method = HTTPMethod(rawValue: "REPORT")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
         
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NCDataFileXML().requestBodyFileListingFavorites.data(using: .utf8)
        } catch {
            queue.async { completionHandler(account, files, NCCError(error: error)) }
            return
        }
         
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, files, error) }
            case .success( _):
                if let data = response.data {
                    files = NCDataFileXML().convertDataFile(data: data, user: NCCommunicationCommon.shared.user, userId: NCCommunicationCommon.shared.userId, showHiddenFiles: showHiddenFiles)
                    queue.async { completionHandler(account, files, .success) }
                } else {
                    queue.async { completionHandler(account, files, .xmlError) }
                }
            }
        }
    }
    
    @objc public func listingTrash(showHiddenFiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ items: [NCCommunicationTrash], _ error: NCCError) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        var items: [NCCommunicationTrash] = []
        let serverUrlFileName = NCCommunicationCommon.shared.urlBase + "/" + NCCommunicationCommon.shared.webDav + "/trashbin/" + NCCommunicationCommon.shared.userId + "/trash/"
            
        guard let url = serverUrlFileName.encodedToUrl else {
            queue.async { completionHandler(account, items, .urlError) }
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
            queue.async { completionHandler(account, items, NCCError(error: error)) }
            return
        }
             
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCError(error: error, afResponse: response)
                queue.async { completionHandler(account, items, error) }
            case .success( _):
                if let data = response.data {
                    items = NCDataFileXML().convertDataTrash(data: data, showHiddenFiles: showHiddenFiles)
                    queue.async { completionHandler(account, items, .success) }
                } else {
                    queue.async { completionHandler(account, items, .xmlError) }
                }
            }
        }
    }
}
