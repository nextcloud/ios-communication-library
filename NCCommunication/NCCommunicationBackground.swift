//
//  NCCommunicationBackground.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 29/10/19.
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

@objc public class NCCommunicationBackground: NSObject, URLSessionTaskDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    @objc public static let shared: NCCommunicationBackground = {
        let instance = NCCommunicationBackground()
        return instance
    }()
        
    //MARK: - Download
    
    @objc public func download(serverUrlFileName: Any, fileNameLocalPath: String, description: String?, session: URLSession) -> URLSessionDownloadTask? {
        
        var url: URL?
        
        if serverUrlFileName is URL {
            url = serverUrlFileName as? URL
        } else if serverUrlFileName is String || serverUrlFileName is NSString {
            url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName as! String) as? URL
        }
        
        guard let urlForRequest = url else { return nil }
        
        var request = URLRequest(url: urlForRequest)
        let loginString = "\(NCCommunicationCommon.shared.user):\(NCCommunicationCommon.shared.password)"
        guard let loginData = loginString.data(using: String.Encoding.utf8) else {
            return nil
        }
        let base64LoginString = loginData.base64EncodedString()
        
        request.setValue(NCCommunicationCommon.shared.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let task = session.downloadTask(with: request)
        
        if description == nil {
            task.taskDescription = fileNameLocalPath
        } else {
            task.taskDescription = fileNameLocalPath + "|" + description!
        }
        
        task.resume()
        
        NCCommunicationCommon.shared.writeLog("Network start download file: \(serverUrlFileName)")
        
        return task
    }
    
    //MARK: - Upload
    
    @objc public func upload(serverUrlFileName: Any, fileNameLocalPath: String, dateCreationFile: Date?, dateModificationFile: Date?, description: String?, session: URLSession) -> URLSessionUploadTask? {
        
        var url: URL?
        
        if serverUrlFileName is URL {
            url = serverUrlFileName as? URL
        } else if serverUrlFileName is String || serverUrlFileName is NSString {
            url = NCCommunicationCommon.shared.encodeStringToUrl(serverUrlFileName as! String) as? URL
        }
        
        guard let urlForRequest = url else {
            return nil
        }
        var request = URLRequest(url: urlForRequest)
        
        let loginString = "\(NCCommunicationCommon.shared.user):\(NCCommunicationCommon.shared.password)"
        guard let loginData = loginString.data(using: String.Encoding.utf8) else {
            return nil
        }
        let base64LoginString = loginData.base64EncodedString()
        
        request.httpMethod = "PUT"
        request.setValue(NCCommunicationCommon.shared.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        if dateCreationFile != nil {
            let sDate = "\(dateCreationFile?.timeIntervalSince1970 ?? 0)"
            request.setValue(sDate, forHTTPHeaderField: "X-OC-CTime")
        }
        if dateModificationFile != nil {
            let sDate = "\(dateModificationFile?.timeIntervalSince1970 ?? 0)"
            request.setValue(sDate, forHTTPHeaderField: "X-OC-MTime")
        }
        
        let task = session.uploadTask(with: request, fromFile: URL.init(fileURLWithPath: fileNameLocalPath))
        
        task.taskDescription = description
        task.resume()
        
        NCCommunicationCommon.shared.writeLog("Network start upload file: \(serverUrlFileName)")
        
        return task
    }
    
    //MARK: - SessionDelegate
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) { }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown else { return }
        guard let url = downloadTask.currentRequest?.url?.absoluteString.removingPercentEncoding else { return }
        let fileName = (url as NSString).lastPathComponent
        let serverUrl = url.replacingOccurrences(of: "/"+fileName, with: "")
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            NCCommunicationCommon.shared.delegate?.downloadProgress?(progress, totalBytes: totalBytesWritten, totalBytesExpected: totalBytesExpectedToWrite, fileName: fileName, serverUrl: serverUrl, session: session, task: downloadTask)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        if let httpResponse = (downloadTask.response as? HTTPURLResponse) {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                let parameter = downloadTask.taskDescription?.components(separatedBy: "|")
                if parameter?.count ?? 0 >= 1 {
                    let destinationFilePath = parameter![0]
                    let destinationUrl = NSURL.fileURL(withPath: destinationFilePath)
                    do {
                        try FileManager.default.removeItem(at: destinationUrl)
                        try FileManager.default.copyItem(at: location, to: destinationUrl)
                    } catch { }
                }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        guard totalBytesExpectedToSend != NSURLSessionTransferSizeUnknown else { return }
        guard let url = task.currentRequest?.url?.absoluteString.removingPercentEncoding else { return }
        let fileName = (url as NSString).lastPathComponent
        let serverUrl = url.replacingOccurrences(of: "/"+fileName, with: "")
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)

        DispatchQueue.main.async {
            NCCommunicationCommon.shared.delegate?.uploadProgress?(progress, totalBytes: totalBytesSent, totalBytesExpected: totalBytesExpectedToSend, fileName: fileName, serverUrl: serverUrl, session: session, task: task)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        var fileName: String = "", serverUrl: String = "", etag: String?, ocId: String?, date: NSDate?, dateLastModified: NSDate?, length: Int64 = 0
        let url = task.currentRequest?.url?.absoluteString.removingPercentEncoding
        if url != nil {
            fileName = (url! as NSString).lastPathComponent
            serverUrl = url!.replacingOccurrences(of: "/"+fileName, with: "")
        }
        
        var errorCode = 0, errorDescription = ""
        
        if let httpResponse = (task.response as? HTTPURLResponse) {
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                if error != nil {
                    errorCode = (error! as NSError).code
                    errorDescription = (error! as NSError).localizedDescription
                }
            } else {
                let error = NCCommunicationError().getError(error: nil, httResponse: httpResponse)
                errorCode = error.errorCode
                errorDescription = error.description ?? ""
            }
        } else {
            if error != nil {
                errorCode = (error! as NSError).code
                errorDescription = (error! as NSError).localizedDescription
            }
        }
        
        if let header = (task.response as? HTTPURLResponse)?.allHeaderFields {
            if NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: header) != nil {
                ocId = NCCommunicationCommon.shared.findHeader("oc-fileid", allHeaderFields: header)
            } else if NCCommunicationCommon.shared.findHeader("fileid", allHeaderFields: header) != nil {
                ocId = NCCommunicationCommon.shared.findHeader("fileid", allHeaderFields: header)
            }
            if NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: header) != nil {
                etag = NCCommunicationCommon.shared.findHeader("oc-etag", allHeaderFields: header)
            } else if NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: header) != nil {
                etag = NCCommunicationCommon.shared.findHeader("etag", allHeaderFields: header)
            }
            if etag != nil { etag = etag!.replacingOccurrences(of: "\"", with: "") }
            if let dateString = NCCommunicationCommon.shared.findHeader("date", allHeaderFields: header)  {
                date = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz")
            }
            if let dateString = header["Last-Modified"] as? String {
                dateLastModified = NCCommunicationCommon.shared.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz")
            }
            length = header["Content-Length"] as? Int64 ?? 0
        }
        
        DispatchQueue.main.async {
            if task is URLSessionDownloadTask {
                var description = task.taskDescription
                let parameter = task.taskDescription?.components(separatedBy: "|")
                if parameter?.count == 2 {
                    description = parameter![1]
                }
                NCCommunicationCommon.shared.delegate?.downloadComplete?(fileName: fileName, serverUrl: serverUrl, etag: etag, date: date, dateLastModified: dateLastModified, length: length, description: description, task: task, errorCode: errorCode, errorDescription: errorDescription)
            }
            if task is URLSessionUploadTask {
                
                NCCommunicationCommon.shared.delegate?.uploadComplete?(fileName: fileName, serverUrl: serverUrl, ocId: ocId, etag: etag, date: date, size: task.countOfBytesExpectedToSend, description: task.taskDescription, task: task, errorCode: errorCode, errorDescription: errorDescription)
            }
            
            if errorCode == 0 {
                NCCommunicationCommon.shared.writeLog("Network completed upload file: " + serverUrl + "/" + fileName)
            } else {
                NCCommunicationCommon.shared.writeLog("Network completed upload file: " + serverUrl + "/" + fileName + " with error code \(errorCode) and error description " + errorDescription)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if NCCommunicationCommon.shared.delegate == nil {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        } else {
            NCCommunicationCommon.shared.delegate?.authenticationChallenge?(session, didReceive: challenge, completionHandler: { authChallengeDisposition, credential in
                completionHandler(authChallengeDisposition, credential)
            })
        }
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            NCCommunicationCommon.shared.delegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
        }
    }
}
