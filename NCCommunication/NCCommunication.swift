//
//  NCCommunication.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/10/19.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
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
import UIKit
import Alamofire
import SwiftyXMLParser
import SwiftyJSON

@objc public class NCCommunication: SessionDelegate {
    @objc public static let sharedInstance: NCCommunication = {
        let instance = NCCommunication()
        return instance
    }()
    
    // Session Manager
    private lazy var sessionManager: Alamofire.Session = {
        let configuration = URLSessionConfiguration.af.default
        return Alamofire.Session(configuration: configuration, delegate: self, rootQueue:  DispatchQueue(label: "com.nextcloud.sessionManagerData.rootQueue"), startRequestsImmediately: true, requestQueue: nil, serializationQueue: nil, interceptor: nil, serverTrustManager: nil, redirectHandler: nil, cachedResponseHandler: nil, eventMonitors: self.makeEvents())
    }()
    
    //MARK: - HTTP Headers
    
    private func getStandardHeaders() -> HTTPHeaders {
        
        var headers: HTTPHeaders = [.authorization(username: NCCommunicationCommon.sharedInstance.username, password: NCCommunicationCommon.sharedInstance.password)]
        if let userAgent = NCCommunicationCommon.sharedInstance.userAgent { headers.update(.userAgent(userAgent)) }
        headers.update(name: "OCS-APIRequest", value: "true")
        
        return headers
    }
    
    //MARK: - monitor
    
    private func makeEvents() -> [EventMonitor] {
        
        let events = ClosureEventMonitor()
        events.requestDidFinish = { request in
            print("Request finished \(request)")
        }
        events.taskDidComplete = { session, task, error in
            print("Request failed \(session) \(task) \(String(describing: error))")
            /*
            if  let urlString = (error as NSError?)?.userInfo["NSErrorFailingURLStringKey"] as? String,
                let resumedata = (error as NSError?)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                print("Found resume data for url \(urlString)")
                //self.startDownload(urlString, resumeData: resumedata)
            }
            */
        }
        return [events]
    }
    
    //MARK: - webDAV

    @objc public func createFolder(_ serverUrlFileName: String, account: String, completionHandler: @escaping (_ account: String, _ ocId: String?, _ date: NSDate?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, nil, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "MKCOL")
               
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, error.errorCode, error.description)
            case .success( _):
                let ocId = response.response?.allHeaderFields["OC-FileId"] as? String
                if let dateString = response.response?.allHeaderFields["Date"] as? String {
                    if let date = NCCommunicationCommon.sharedInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, ocId, date, 0, nil)
                    } else { completionHandler(account, nil, nil, NSURLErrorBadServerResponse, "Response error decode date format") }
                } else { completionHandler(account, nil, nil, NSURLErrorBadServerResponse, "Response error decode date format") }
            }
        }
    }
    
    @objc public func deleteFileOrFolder(_ serverUrlFileName: String, account: String, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "DELETE")
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
    
    @objc public func moveFileOrFolder(serverUrlFileNameSource: String, serverUrlFileNameDestination: String, account: String, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileNameSource) else {
            completionHandler(account, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "MOVE")
        
        // headers
        var headers = getStandardHeaders()
        headers.update(name: "Destination", value: serverUrlFileNameDestination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        headers.update(name: "Overwrite", value: "T")
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
    
    @objc public func readFileOrFolder(serverUrlFileName: String, depth: String, account: String, completionHandler: @escaping (_ account: String, _ files: [NCFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        var serverUrlFileName = String(serverUrlFileName)
        if depth == "1" && serverUrlFileName.last != "/" { serverUrlFileName = serverUrlFileName + "/" }
        if depth == "0" && serverUrlFileName.last == "/" { serverUrlFileName = String(serverUrlFileName.remove(at: serverUrlFileName.index(before: serverUrlFileName.endIndex))) }
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "PROPFIND")
        
        // headers
        var headers = getStandardHeaders()
        headers.update(.contentType("application/xml"))
        headers.update(name: "Depth", value: depth)

        // request
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
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let files = NCDataFileXML().convertDataFile(data: data)
                    completionHandler(account, files, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, "Response error decode XML")
                }
            }
        }
    }
    
    @objc public func setFavorite(urlString: String, fileName: String, favorite: Bool, account: String, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        let serverUrlFileName = urlString + "/remote.php/dav/files/" + NCCommunicationCommon.sharedInstance.username + "/" + fileName
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "PROPPATCH")
        
        // request
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: getStandardHeaders())
            let body = NSString.init(format: NCDataFileXML().requestBodyFileSetFavorite as NSString, (favorite ? 1 : 0)) as String
            urlRequest.httpBody = body.data(using: .utf8)
        } catch {
            completionHandler(account, error._code, error.localizedDescription)
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description)
            case .success( _):
                completionHandler(account, 0, nil)
            }
        }
    }
    
    @objc public func listingFavorites(urlString: String, account: String, completionHandler: @escaping (_ account: String, _ files: [NCFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        let serverUrlFileName = urlString + "/remote.php/dav/files/" + NCCommunicationCommon.sharedInstance.username
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "REPORT")
        
        // request
        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: getStandardHeaders())
            urlRequest.httpBody = NCDataFileXML().requestBodyFileListingFavorites.data(using: .utf8)
        } catch {
            completionHandler(account, nil, error._code, error.localizedDescription)
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    let files = NCDataFileXML().convertDataFile(data: data)
                    completionHandler(account, files, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, "Response error decode XML")
                }
            }
        }
    }
    
    //MARK: - API
    
    @objc public func downloadPreview(serverUrl: String, fileNamePath: String, fileNameLocalPath: String, width: CGFloat, height: CGFloat, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        // url
        var serverUrl = String(serverUrl)
        if serverUrl.last != "/" { serverUrl = serverUrl + "/" }
        serverUrl = serverUrl + "index.php/core/preview.png?file=" + fileNamePath + "&x=\(width)&y=\(height)&a=1&mode=cover"
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrl) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "GET")
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    do {
                        let url = URL.init(fileURLWithPath: fileNameLocalPath)
                        try  data.write(to: url, options: .atomic)
                        completionHandler(account, data, 0, nil)
                    } catch {
                        completionHandler(account, nil, error._code, error.localizedDescription)
                    }
                } else {
                    completionHandler(account, nil, NSURLErrorCannotDecodeContentData, "Response error data null")
                }
            }
        }
    }
    
    @objc public func getExternalSite(urlString: String, account: String, completionHandler: @escaping (_ account: String, _ externalFiles: [NCExternalFile], _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        var externalFiles = [NCExternalFile]()

        // url
        var urlString = String(urlString)
        if urlString.last != "/" { urlString = urlString + "/" }
        urlString = urlString + "ocs/v2.php/apps/external/api/v1?format=json"
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(urlString) else {
            completionHandler(account, externalFiles, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "GET")
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, externalFiles, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let ocsdata = json["ocs"]["data"]
                for (_, subJson):(String, JSON) in ocsdata {
                    let extrernalFile = NCExternalFile()
                    if let id = subJson["id"].int { extrernalFile.idExternalSite = id }
                    if let name = subJson["name"].string { extrernalFile.name = name }
                    if let url = subJson["url"].string { extrernalFile.url = url }
                    if let lang = subJson["lang"].string { extrernalFile.lang = lang }
                    if let icon = subJson["icon"].string { extrernalFile.icon = icon }
                    if let type = subJson["type"].string { extrernalFile.type = type }
                    externalFiles.append(extrernalFile)
                }
                completionHandler(account, externalFiles, 0, nil)
            }
        }
    }
    
    @objc public func getServerStatus(urlString: String, completionHandler: @escaping (_ serverProductName: String?, _ serverVersion: String? , _ versionMajor: Int, _ versionMinor: Int, _ versionMicro: Int, _ extendedSupport: Bool, _ errorCode: Int, _ errorDescription: String?) -> Void) {
                
        // url
        var urlString = String(urlString)
        if urlString.last != "/" { urlString = urlString + "/" }
        urlString = urlString + "status.php"
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(urlString) else {
            completionHandler(nil, nil, 0, 0, 0, false, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        // method
        let method = HTTPMethod(rawValue: "GET")
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(nil, nil, 0, 0, 0, false, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                var versionMajor = 0, versionMinor = 0, versionMicro = 0
                
                let serverProductName = json["productname"].string?.lowercased() ?? ""
                let serverVersion = json["version"].string ?? ""
                let serverVersionString = json["versionstring"].string ?? ""
                let extendedSupport = json["extendedSupport"].bool ?? false
                    
                let arrayVersion = serverVersion.components(separatedBy: ".")
                if arrayVersion.count == 1 {
                    versionMajor = Int(arrayVersion[0]) ?? 0
                } else if arrayVersion.count == 2 {
                    versionMajor = Int(arrayVersion[0]) ?? 0
                    versionMinor = Int(arrayVersion[1]) ?? 0
                } else if arrayVersion.count >= 3 {
                    versionMajor = Int(arrayVersion[0]) ?? 0
                    versionMinor = Int(arrayVersion[1]) ?? 0
                    versionMicro = Int(arrayVersion[2]) ?? 0
                }
                
                completionHandler(serverProductName, serverVersionString, versionMajor, versionMinor, versionMicro, extendedSupport, 0, "")
            }
        }
    }
    //MARK: - File transfer
    
    @objc public func download(serverUrlFileName: String, fileNameLocalPath: String, account: String, progressHandler: @escaping (_ progress: Progress) -> Void , completionHandler: @escaping (_ account: String, _ etag: String?, _ date: NSDate?, _ lenght: Double, _ errorCode: Int, _ errorDescription: String?) -> Void) -> URLSessionTask? {
        
        // url
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, nil, nil, 0, NSURLErrorUnsupportedURL, "Invalid server url")
            return nil
        }
        
        // destination
        var destination: Alamofire.DownloadRequest.Destination?
        let fileNamePathLocalDestinationURL = NSURL.fileURL(withPath: fileNameLocalPath)
        let destinationFile: DownloadRequest.Destination = { _, _ in
            return (fileNamePathLocalDestinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        destination = destinationFile
        
        let request = sessionManager.download(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: getStandardHeaders(), interceptor: nil, to: destination)
        .downloadProgress { progress in
            progressHandler(progress)
        }
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, 0, error.errorCode, error.description)
            case .success( _):
                let lenght = response.response?.allHeaderFields["lenght"] as? Double ?? 0
                var etag = response.response?.allHeaderFields["OC-ETag"] as? String
                if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
                if let dateString = response.response?.allHeaderFields["Date"] as? String {
                    if let date = NCCommunicationCommon.sharedInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, etag, date, lenght, 0, nil)
                    } else { completionHandler(account, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
                } else { completionHandler(account, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
            }
        }
        
        return request.task
    }
    
    @objc public func upload(serverUrlFileName: String, fileNameLocalPath: String, account: String, progressHandler: @escaping (_ progress: Progress) -> Void ,completionHandler: @escaping (_ account: String, _ ocId: String?, _ etag: String?, _ date: NSDate?, _ errorCode: Int, _ errorDescription: String?) -> Void) -> URLSessionTask? {
        
        // url
        guard let url = NCCommunicationCommon.sharedInstance.encodeUrlString(serverUrlFileName) else {
            completionHandler(account, nil, nil, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return nil
        }
        let fileNameLocalPathUrl = URL.init(fileURLWithPath: fileNameLocalPath)
        
        let request = sessionManager.upload(fileNameLocalPathUrl, to: url, method: .put, headers: getStandardHeaders(), interceptor: nil, fileManager: .default)
        .uploadProgress { progress in
            progressHandler(progress)
        }
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, nil, error.errorCode, error.description)
            case .success( _):
                let ocId = response.response?.allHeaderFields["OC-FileId"] as? String
                var etag = response.response?.allHeaderFields["OC-ETag"] as? String
                if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
                if let dateString = response.response?.allHeaderFields["Date"] as? String {
                    if let date = NCCommunicationCommon.sharedInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, ocId, etag, date, 0, nil)
                    } else { completionHandler(account, nil, nil, nil, NSURLErrorBadServerResponse, "Response error decode date format") }
                } else { completionHandler(account, nil, nil, nil, NSURLErrorBadServerResponse, "Response error decode date format") }
            }
        }
        
        return request.task
    }
    
    //MARK: - SessionDelegate

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        NCCommunicationCommon.sharedInstance.authenticationChallenge(challenge, completionHandler: { (authChallengeDisposition, credential) in
            completionHandler(authChallengeDisposition, credential)
        })
    }
}

