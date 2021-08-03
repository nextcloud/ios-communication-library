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
import Alamofire
import SwiftyJSON

@objc public class NCCommunication: SessionDelegate {
    @objc public static let shared: NCCommunication = {
        let instance = NCCommunication()
        return instance
    }()
            
    internal lazy var sessionManager: Alamofire.Session = {
        let configuration = URLSessionConfiguration.af.default
        return Alamofire.Session(configuration: configuration, delegate: self, rootQueue: DispatchQueue(label: "com.nextcloud.sessionManagerData.rootQueue"), startRequestsImmediately: true, requestQueue: nil, serializationQueue: nil, interceptor: nil, serverTrustManager: nil, redirectHandler: nil, cachedResponseHandler: nil, eventMonitors: [AlamofireLogger()])
    }()
    
    private let reachabilityManager = Alamofire.NetworkReachabilityManager()
    
    override public init(fileManager: FileManager = .default) {
        super.init(fileManager: fileManager)
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeUser(_:)), name: NSNotification.Name(rawValue: "changeUser"), object: nil)
        
        startNetworkReachabilityObserver()
    }
    
    //MARK: - Notification Center
    
    @objc func changeUser(_ notification: NSNotification) {
        sessionDeleteCookies()
        NCCommunicationCommon.shared.externalUTI = []
    }
    
    //MARK: -  Cookies
   
    internal func saveCookiesTEST(response : HTTPURLResponse?) {
        if let headerFields = response?.allHeaderFields as? [String : String] {
            if let url = URL(string: NCCommunicationCommon.shared.urlBase) {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                if cookies.count > 0 {
                    NCCommunicationCommon.shared.cookies[NCCommunicationCommon.shared.account] = cookies
                } else {
                    NCCommunicationCommon.shared.cookies[NCCommunicationCommon.shared.account] = nil
                }
            }
        }
    }
    
    internal func injectsCookiesTEST() {
        if let cookies = NCCommunicationCommon.shared.cookies[NCCommunicationCommon.shared.account] {
            if let url = URL(string: NCCommunicationCommon.shared.urlBase) {
                sessionManager.session.configuration.httpCookieStorage?.setCookies(cookies, for: url, mainDocumentURL: nil)
            }
        }
    }
    
    @objc public func sessionDeleteCookies() {
        if let cookieStore = sessionManager.session.configuration.httpCookieStorage {
            for cookie in cookieStore.cookies ?? [] {
                cookieStore.deleteCookie(cookie)
            }
        }
    }
        
    //MARK: - Reachability
    
    @objc public func isNetworkReachable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }
    
    private func startNetworkReachabilityObserver() {
        
        reachabilityManager?.startListening(onUpdatePerforming: { (status) in
            switch status {

            case .unknown :
                NCCommunicationCommon.shared.delegate?.networkReachabilityObserver?(NCCommunicationCommon.typeReachability.unknown)

            case .notReachable:
                NCCommunicationCommon.shared.delegate?.networkReachabilityObserver?(NCCommunicationCommon.typeReachability.notReachable)
                
            case .reachable(.ethernetOrWiFi):
                NCCommunicationCommon.shared.delegate?.networkReachabilityObserver?(NCCommunicationCommon.typeReachability.reachableEthernetOrWiFi)

            case .reachable(.cellular):
                NCCommunicationCommon.shared.delegate?.networkReachabilityObserver?(NCCommunicationCommon.typeReachability.reachableCellular)
            }
        })
    }
    
    //MARK: - Session utility
        
    @objc public func getSessionManager() -> URLSession {
       return sessionManager.session
    }
    
    /*
    //MARK: -
    
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
    */
    
    //MARK: - download / upload
    
    @objc public func download(serverUrlFileName: Any, fileNameLocalPath: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil,
                               taskHandler: @escaping (_ task: URLSessionTask) -> () = { _ in },
                               progressHandler: @escaping (_ progress: Progress) -> () = { _ in },
                               completionHandler: @escaping (_ account: String, _ etag: String?, _ date: NSDate?, _ lenght: Int64, _ allHeaderFields: [AnyHashable : Any]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        download(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders) { (request) in
            // not available in objc
        } taskHandler: { (task) in
            taskHandler(task)
        } progressHandler: { (progress) in
            progressHandler(progress)
        } completionHandler: { (account, etag, date, lenght, allHeaderFields, error, errorCode, errorDescription) in
            // error not available in objc
            completionHandler(account, etag, date, lenght, allHeaderFields, errorCode, errorDescription)
        }
    }
    
    public func download(serverUrlFileName: Any, fileNameLocalPath: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil,
                         requestHandler: @escaping (_ request: DownloadRequest) -> () = { _ in },
                         taskHandler: @escaping (_ task: URLSessionTask) -> () = { _ in },
                         progressHandler: @escaping (_ progress: Progress) -> () = { _ in },
                         completionHandler: @escaping (_ account: String, _ etag: String?, _ date: NSDate?, _ lenght: Int64, _ allHeaderFields: [AnyHashable : Any]?, _ error: AFError?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        var convertible: URLConvertible?
        
        if serverUrlFileName is URL {
            convertible = serverUrlFileName as? URLConvertible
        } else if serverUrlFileName is String || serverUrlFileName is NSString {
            convertible = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName as! String)
        }
        
        guard let url = convertible else {
            completionHandler(account, nil, nil, 0, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        var destination: Alamofire.DownloadRequest.Destination?
        let fileNamePathLocalDestinationURL = NSURL.fileURL(withPath: fileNameLocalPath)
        let destinationFile: DownloadRequest.Destination = { _, _ in
            return (fileNamePathLocalDestinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        destination = destinationFile
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        let request = sessionManager.download(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil, to: destination).validate(statusCode: 200..<300).onURLSessionTaskCreation { (task) in
            
            taskHandler(task)
            
        } .downloadProgress { progress in
            
            progressHandler(progress)
            
        } .response { response in
            
            switch response.result {
            case .failure(let error):
                let resultError = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, 0, nil, error, resultError.errorCode, resultError.description ?? "")
            case .success( _):

                var date: NSDate?
                var etag: String?
                var length: Int64 = 0
                let allHeaderFields = response.response?.allHeaderFields
                                
                if let result = response.response?.allHeaderFields["Content-Length"] as? String {
                    length = Int64(result) ?? 0
                }
                
                if NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: response.response?.allHeaderFields)
                }
                
                if etag != nil {
                    etag = etag!.replacingOccurrences(of: "\"", with: "")
                }
                
                if let dateString = NCCommunicationCommon.shared.findHeader("Date", allHeaderFields: response.response?.allHeaderFields) {
                    date = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz")
                }
                
                completionHandler(account, etag, date, length, allHeaderFields, nil , 0, "")
            }
        }
        
        DispatchQueue.main.async {
            requestHandler(request)
        }
    }
    
    @objc public func upload(serverUrlFileName: String, fileNameLocalPath: String, dateCreationFile: Date? = nil, dateModificationFile: Date? = nil, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil,
                             taskHandler: @escaping (_ task: URLSessionTask) -> () = { _ in },
                             progressHandler: @escaping (_ progress: Progress) -> () = { _ in },
                             completionHandler: @escaping (_ account: String, _ ocId: String?, _ etag: String?, _ date: NSDate?, _ size: Int64, _ allHeaderFields: [AnyHashable : Any]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        upload(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: dateCreationFile, dateModificationFile: dateModificationFile, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders) { (request) in
            // not available in objc
        } taskHandler: { (task) in
            taskHandler(task)
        } progressHandler: { (progress) in
            progressHandler(progress)
        } completionHandler: { (account, ocId, etag, date, size, allHeaderFields, error, errorCode, errorDescription) in
            // error not available in objc
            completionHandler(account, ocId, etag, date, size, allHeaderFields, errorCode, errorDescription)
        }
    }

    public func upload(serverUrlFileName: Any, fileNameLocalPath: String, dateCreationFile: Date? = nil, dateModificationFile: Date? = nil, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil,
                       requestHandler: @escaping (_ request: UploadRequest) -> () = { _ in },
                       taskHandler: @escaping (_ task: URLSessionTask) -> () = { _ in },
                       progressHandler: @escaping (_ progress: Progress) -> () = { _ in },
                       completionHandler: @escaping (_ account: String, _ ocId: String?, _ etag: String?, _ date: NSDate?, _ size: Int64, _ allHeaderFields: [AnyHashable : Any]?, _ error: AFError?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        var convertible: URLConvertible?
        var size: Int64 = 0

        if serverUrlFileName is URL {
            convertible = serverUrlFileName as? URLConvertible
        } else if serverUrlFileName is String || serverUrlFileName is NSString {
            convertible = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName as! String)
        }
        
        guard let url = convertible else {
            completionHandler(account, nil, nil, nil, 0, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let fileNameLocalPathUrl = URL.init(fileURLWithPath: fileNameLocalPath)
        
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        if dateCreationFile != nil {
            let sDate = "\(dateCreationFile?.timeIntervalSince1970 ?? 0)"
            headers.update(name: "X-OC-CTime", value: sDate)
        }
        if dateModificationFile != nil {
            let sDate = "\(dateModificationFile?.timeIntervalSince1970 ?? 0)"
            headers.update(name: "X-OC-MTime", value: sDate)
        }
        
        let request = sessionManager.upload(fileNameLocalPathUrl, to: url, method: .put, headers: headers, interceptor: nil, fileManager: .default).validate(statusCode: 200..<300).onURLSessionTaskCreation(perform: { (task) in
            
            taskHandler(task)
            
        }) .uploadProgress { progress in
            
            progressHandler(progress)
            size = progress.totalUnitCount
            
        } .response { response in
            
            switch response.result {
            case .failure(let error):
                let resultError = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, nil, 0, nil, error, resultError.errorCode, resultError.description ?? "")
            case .success( _):
                var ocId: String?, etag: String?
                let allHeaderFields = response.response?.allHeaderFields

                if NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields) != nil {
                    ocId = NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.shared.findHeader("fileid", allHeaderFields: response.response?.allHeaderFields) != nil {
                    ocId = NCCommunicationCommon.shared.findHeader("fileid", allHeaderFields: response.response?.allHeaderFields)
                }
                
                if NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: response.response?.allHeaderFields)
                }
                
                if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
                
                if let dateString = NCCommunicationCommon.shared.findHeader("date", allHeaderFields: response.response?.allHeaderFields) {
                    if let date = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, ocId, etag, date, size, allHeaderFields, nil, 0, "")
                    } else {
                        completionHandler(account, nil, nil, nil, 0, allHeaderFields, nil, NSURLErrorBadServerResponse, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
                    }
                } else {
                    completionHandler(account, nil, nil, nil, 0, allHeaderFields, nil, NSURLErrorBadServerResponse, NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
                }
            }
        }
        
        DispatchQueue.main.async {
            requestHandler(request)
        }
    }
    
    //MARK: - SessionDelegate

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if NCCommunicationCommon.shared.delegate == nil {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        } else {
            NCCommunicationCommon.shared.delegate?.authenticationChallenge?(session, didReceive: challenge, completionHandler: { authChallengeDisposition, credential in
                completionHandler(authChallengeDisposition, credential)
            })
        }
    }
}

final class AlamofireLogger: EventMonitor {

    func requestDidResume(_ request: Request) {
        
        if NCCommunicationCommon.shared.levelLog > 0 {
        
            NCCommunicationCommon.shared.writeLog("Network request started: \(request)")
        
            if NCCommunicationCommon.shared.levelLog > 1 {
                
                let allHeaders = request.request.flatMap { $0.allHTTPHeaderFields.map { $0.description } } ?? "None"
                let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
                
                NCCommunicationCommon.shared.writeLog("Network request headers: \(allHeaders)")
                NCCommunicationCommon.shared.writeLog("Network request body: \(body)")
            }
        }
    }
    
    func request<Value>(_ request: DataRequest, didParseResponse response: AFDataResponse<Value>) {
        
        guard let date = NCCommunicationCommon.shared.convertDate(Date(), format: "yyyy-MM-dd' 'HH:mm:ss") else { return }
        let responseResultString = String.init("\(response.result)")
        let responseDebugDescription = String.init("\(response.debugDescription)")
        let responseAllHeaderFields = String.init("\(String(describing: response.response?.allHeaderFields))")
        
        if NCCommunicationCommon.shared.levelLog > 0 {
            
            if NCCommunicationCommon.shared.levelLog == 1 {
                
                if let request = response.request {
                    let requestString = "\(request)"
                    NCCommunicationCommon.shared.writeLog("Network response request: " + requestString + ", result: " + responseResultString)
                } else {
                    NCCommunicationCommon.shared.writeLog("Network response result: " + responseResultString)
                }
                
            } else {
                
                NCCommunicationCommon.shared.writeLog("Network response result: \(date) " + responseDebugDescription)
                NCCommunicationCommon.shared.writeLog("Network response all headers: \(date) " + responseAllHeaderFields)
            }
        }
    }
}
