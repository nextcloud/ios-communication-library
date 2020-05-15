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
import SwiftyJSON

@objc public class NCCommunication: SessionDelegate {
    @objc public static let sharedInstance: NCCommunication = {
        let instance = NCCommunication()
        return instance
    }()
    
    // Session Manager
    
    lazy var sessionManager: Alamofire.Session = {
        let configuration = URLSessionConfiguration.af.default
        return Alamofire.Session(configuration: configuration, delegate: self, rootQueue:  DispatchQueue(label: "com.nextcloud.sessionManagerData.rootQueue"), startRequestsImmediately: true, requestQueue: nil, serializationQueue: nil, interceptor: nil, serverTrustManager: nil, redirectHandler: nil, cachedResponseHandler: nil, eventMonitors: self.makeEvents())
    }()
    
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
    
    //MARK: - download / upload
    
    @objc public func download(serverUrlFileName: String, fileNameLocalPath: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, progressHandler: @escaping (_ progress: Progress) -> Void , completionHandler: @escaping (_ account: String, _ etag: String?, _ date: NSDate?, _ lenght: Double, _ errorCode: Int, _ errorDescription: String?) -> Void) -> URLSessionTask? {
        
        guard let url = NCCommunicationCommon.sharedInstance.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, nil, 0, NSURLErrorUnsupportedURL, "Invalid server url")
            return nil
        }
        
        var destination: Alamofire.DownloadRequest.Destination?
        let fileNamePathLocalDestinationURL = NSURL.fileURL(withPath: fileNameLocalPath)
        let destinationFile: DownloadRequest.Destination = { _, _ in
            return (fileNamePathLocalDestinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        destination = destinationFile
        
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        let request = sessionManager.download(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil, to: destination)
        .downloadProgress { progress in
            progressHandler(progress)
        }
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, 0, error.errorCode, error.description)
            case .success( _):
                var etag: String?
                let length = response.response?.allHeaderFields["length"] as? Double ?? 0
                if NCCommunicationCommon.sharedInstance.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.sharedInstance.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.sharedInstance.findHeader("etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.sharedInstance.findHeader("etag", allHeaderFields: response.response?.allHeaderFields)
                }
                if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
                if let dateString = NCCommunicationCommon.sharedInstance.findHeader("Date", allHeaderFields: response.response?.allHeaderFields) {
                    if let date = NCCommunicationCommon.sharedInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, etag, date, length, 0, nil)
                    } else { completionHandler(account, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
                } else { completionHandler(account, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
            }
        }
        
        return request.task
    }
    
    @objc public func upload(serverUrlFileName: String, fileNameLocalPath: String, dateCreationFile: Date?, dateModificationFile: Date?, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, progressHandler: @escaping (_ progress: Progress) -> Void ,completionHandler: @escaping (_ account: String, _ ocId: String?, _ etag: String?, _ date: NSDate?, _ size: Int64, _ errorCode: Int, _ errorDescription: String?) -> Void) -> URLSessionTask? {
        
        guard let url = NCCommunicationCommon.sharedInstance.encodeStringToUrl(serverUrlFileName) else {
            completionHandler(account, nil, nil, nil, 0, NSURLErrorUnsupportedURL, "Invalid server url")
            return nil
        }
        let fileNameLocalPathUrl = URL.init(fileURLWithPath: fileNameLocalPath)
        
        var headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        if dateCreationFile != nil {
            let sDate = "\(dateCreationFile?.timeIntervalSince1970 ?? 0)"
            headers.update(name: "X-OC-Ctime", value: sDate)
        }
        if dateModificationFile != nil {
            let sDate = "\(dateModificationFile?.timeIntervalSince1970 ?? 0)"
            headers.update(name: "X-OC-Mtime", value: sDate)
        }
        
        var size: Int64 = 0
        let request = sessionManager.upload(fileNameLocalPathUrl, to: url, method: .put, headers: headers, interceptor: nil, fileManager: .default)
        .uploadProgress { progress in
            progressHandler(progress)
            size = progress.totalUnitCount
        }
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, nil, nil, 0, error.errorCode, error.description)
            case .success( _):
                var ocId: String?, etag: String?
                if NCCommunicationCommon.sharedInstance.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields) != nil {
                    ocId = NCCommunicationCommon.sharedInstance.findHeader("oc-fileid", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.sharedInstance.findHeader("fileid", allHeaderFields: response.response?.allHeaderFields) != nil {
                    ocId = NCCommunicationCommon.sharedInstance.findHeader("fileid", allHeaderFields: response.response?.allHeaderFields)
                }
                if NCCommunicationCommon.sharedInstance.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.sharedInstance.findHeader("oc-etag", allHeaderFields: response.response?.allHeaderFields)
                } else if NCCommunicationCommon.sharedInstance.findHeader("etag", allHeaderFields: response.response?.allHeaderFields) != nil {
                    etag = NCCommunicationCommon.sharedInstance.findHeader("etag", allHeaderFields: response.response?.allHeaderFields)
                }
                if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
                if let dateString = NCCommunicationCommon.sharedInstance.findHeader("date", allHeaderFields: response.response?.allHeaderFields) {
                    if let date = NCCommunicationCommon.sharedInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz") {
                        completionHandler(account, ocId, etag, date, size, 0, nil)
                    } else { completionHandler(account, nil, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
                } else { completionHandler(account, nil, nil, nil, 0, NSURLErrorBadServerResponse, "Response error decode date format") }
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

