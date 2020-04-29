//
//  NCCommunicationCommon.swift
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
import MobileCoreServices

@objc public protocol NCCommunicationCommonDelegate {
    @objc optional func authenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    @objc optional func downloadProgress(_ progress: Double, fileName: String, ServerUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func uploadProgress(_ progress: Double, fileName: String, ServerUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func downloadComplete(fileName: String, serverUrl: String, etag: String?, date: NSDate?, dateLastModified: NSDate?, length: Double, description: String?, error: Error?, statusCode: Int)
    @objc optional func uploadComplete(fileName: String, serverUrl: String, ocId: String?, etag: String?, date: NSDate?, size: Int64, description: String?, error: Error?, statusCode: Int)
}

@objc public class NCCommunicationCommon: NSObject {
    @objc public static let sharedInstance: NCCommunicationCommon = {
        let instance = NCCommunicationCommon()
        return instance
    }()
    
    var user = ""
    var userId = ""
    var password = ""
    var url = ""
    var userAgent: String?
    var capabilitiesGroup: String?
    var nextcloudVersion: Int = 0
    var webDavRoot: String = "remote.php/webdav"
    var davRoot: String = "remote.php/dav"
    
    // Protocol
    var delegate: NCCommunicationCommonDelegate?
    
    // Session
    @objc let sessionMaximumConnectionsPerHost = 5
    @objc let sessionIdentifierBackground: String = "com.nextcloud.session.background"
    @objc let sessionIdentifierBackgroundwifi: String = "com.nextcloud.session.backgroundwifi"
    @objc let sessionIdentifierExtension: String = "com.nextcloud.session.extension"
    
    // Constant
    let k_encodeCharacterSet = " #;?@&=$+{}<>,!'*|"
    
    enum typeFile: String {
        case audio = "audio"
        case compress = "compress"
        case directory = "directory"
        case document = "document"
        case image = "image"
        case imagemeter = "imagemeter"
        case unknow = "unknow"
        case video = "video"
    }

    enum iconName: String {
        case audio = "file_audio"
        case code = "file_code"
        case compress = "file_compress"
        case directory = "directory"
        case document = "document"
        case image = "file_photo"
        case imagemeter = "imagemeter"
        case movie = "file_movie"
        case pdf = "file_pdf"
        case ppt = "file_ppt"
        case txt = "file_txt"
        case unknow = "file"
        case xls = "file_xls"
    }

    //MARK: - Setup
    
    @objc public func setup(user: String, userId: String, password: String, url: String, userAgent: String?, capabilitiesGroup: String?, nextcloudVersion: Int, delegate: NCCommunicationCommonDelegate?) {
        
        self.user = user
        self.userId = userId
        self.password = password
        self.url = url
        self.userAgent = userAgent
        self.capabilitiesGroup = capabilitiesGroup
        self.nextcloudVersion = nextcloudVersion
        self.delegate = delegate
    }
    
    @objc public func setup(userAgent: String?, capabilitiesGroup: String?, delegate: NCCommunicationCommonDelegate?) {
        
        self.userAgent = userAgent
        self.capabilitiesGroup = capabilitiesGroup
        self.delegate = delegate
    }
    
    @objc public func setup(webDavRoot: String) {
        
        self.webDavRoot = webDavRoot
        
        if webDavRoot.first == "/" { self.webDavRoot = String(self.webDavRoot.dropFirst()) }
        if webDavRoot.last == "/" { self.webDavRoot = String(self.webDavRoot.dropLast()) }
    }
    
    @objc public func setup(davRoot: String) {
        
        self.davRoot = davRoot
        
        if davRoot.first == "/" { self.davRoot = String(self.davRoot.dropFirst()) }
        if davRoot.last == "/" { self.davRoot = String(self.davRoot.dropLast()) }
    }
    
    //MARK: -  Delegate session
    
    public func authenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if delegate == nil {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        } else {
            delegate?.authenticationChallenge?(challenge, completionHandler: { (authChallengeDisposition, credential) in
                completionHandler(authChallengeDisposition, credential)
            })
        }
    }
    
    public func downloadProgress(_ progress: Double, fileName: String, ServerUrl: String, session: URLSession, task: URLSessionTask) {
        delegate?.downloadProgress?(progress, fileName: fileName, ServerUrl: ServerUrl, session: session, task: task)
    }

    public func uploadProgress(_ progress: Double, fileName: String, ServerUrl: String, session: URLSession, task: URLSessionTask) {
        delegate?.uploadProgress?(progress, fileName: fileName, ServerUrl: ServerUrl, session: session, task: task)
    }
    
    public func uploadComplete(fileName: String, serverUrl: String, ocId: String?, etag: String?, date: NSDate?, size: Int64, description: String?, error: Error?, statusCode: Int) {
        delegate?.uploadComplete?(fileName: fileName, serverUrl: serverUrl, ocId: ocId, etag: etag, date: date, size: size, description: description, error: error, statusCode: statusCode)
    }
    
    public func downloadComplete(fileName: String, serverUrl: String, etag: String?, date: NSDate?, dateLastModified: NSDate?, length: Double, description: String?, error: Error?, statusCode: Int) {
        delegate?.downloadComplete?(fileName: fileName, serverUrl: serverUrl, etag: etag, date: date, dateLastModified: dateLastModified, length: length, description: description, error: error, statusCode: statusCode)
    }

    //MARK: - Common
    
    func convertDate(_ dateString: String, format: String) -> NSDate? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: dateString) {
            return date as NSDate
        } else {
            return nil
        }
    }
    
    func convertDate(_ date: Date, format: String) -> String? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
        
    func encodeStringToUrl(_ string: String) -> URLConvertible? {
        
        if let escapedString = encodeString(string) {
            return StringToUrl(escapedString)
        }
        return nil
    }
    
    func encodeString(_ string: String) -> String? {
        
        let allowedCharacterSet = (CharacterSet(charactersIn: k_encodeCharacterSet).inverted)
        let encodeString = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        
        return encodeString
    }
        
    func StringToUrl(_ string: String) -> URLConvertible? {
        
        var url: URLConvertible
        do {
            try url = string.asURL()
            return url
        } catch _ {
            return nil
        }
    }
    
    func findHeader(_ header: String, allHeaderFields: [AnyHashable : Any]?) -> String? {
       
        guard let allHeaderFields = allHeaderFields else { return nil }
        let keyValues = allHeaderFields.map { (String(describing: $0.key).lowercased(), String(describing: $0.value)) }
        
        if let headerValue = keyValues.filter({ $0.0 == header.lowercased() }).first {
            return headerValue.1
        }
        return nil
    }
    
    func getHostName(urlString: String) -> String? {
        
        if let url = URL(string: urlString) {
            guard let hostName = url.host else { return nil }
            guard let scheme = url.scheme else { return nil }
            return scheme + "://" + hostName
        }
        return nil
    }
    
    func getHostNameComponent(urlString: String) -> String? {
        
        if let url = URL(string: urlString) {
            let components = url.pathComponents
            return components.joined(separator: "")
        }
        return nil
    }
    
    public func getInternalContenType(fileName: String, contentType: String, directory: Bool) -> (contentType: String, typeFile: String, iconName: String) {
        
        var resultContentType = contentType
        var resultTypeFile = "", resultIconName = ""
        
        // UTI
        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (fileName as NSString).pathExtension as CFString, nil) {
            let fileUTI = unmanagedFileUTI.takeRetainedValue()
            let ext = (fileName as NSString).pathExtension.lowercased()
            
            // contentType detect
            if contentType == "" {
                if let mimeUTI = UTTypeCopyPreferredTagWithClass(fileUTI, kUTTagClassMIMEType) {
                    resultContentType = mimeUTI.takeRetainedValue() as String
                }
            }
            
            if directory {
                resultTypeFile = typeFile.directory.rawValue
                resultIconName = iconName.directory.rawValue
            } else if UTTypeConformsTo(fileUTI, kUTTypeImage) {
                resultTypeFile = typeFile.image.rawValue
                resultIconName = iconName.image.rawValue
            } else if UTTypeConformsTo(fileUTI, kUTTypeMovie) {
                resultTypeFile = typeFile.video.rawValue
                resultIconName = iconName.movie.rawValue
            } else if UTTypeConformsTo(fileUTI, kUTTypeAudio) {
                resultTypeFile = typeFile.audio.rawValue
                resultIconName = iconName.audio.rawValue
            } else if UTTypeConformsTo(fileUTI, kUTTypeContent) {
                resultTypeFile = typeFile.document.rawValue
                if fileUTI as String == "com.adobe.pdf" {
                    resultIconName = iconName.pdf.rawValue
                } else if fileUTI as String == "org.openxmlformats.wordprocessingml.document" || fileUTI as String == "com.microsoft.word.doc" {
                    resultIconName = iconName.document.rawValue
                } else if fileUTI as String == "org.openxmlformats.spreadsheetml.sheet" || fileUTI as String == "com.microsoft.excel.xls" {
                    resultIconName = iconName.xls.rawValue
                } else if fileUTI as String == "org.openxmlformats.presentationml.presentation" || fileUTI as String == "com.microsoft.powerpoint.ppt" {
                    resultIconName = iconName.ppt.rawValue
                } else if fileUTI as String == "public.plain-text" {
                    resultIconName = iconName.txt.rawValue
                } else if fileUTI as String == "public.html" {
                    resultIconName = iconName.code.rawValue
                } else {
                    resultIconName = iconName.document.rawValue
                }
            } else if UTTypeConformsTo(fileUTI, kUTTypeZipArchive) {
                resultTypeFile = typeFile.compress.rawValue
                resultIconName = iconName.compress.rawValue
            } else if ext == "imi" {
                resultTypeFile = typeFile.imagemeter.rawValue
                resultIconName = iconName.imagemeter.rawValue
            } else {
                resultTypeFile = typeFile.unknow.rawValue
                resultIconName = iconName.unknow.rawValue
            }
        }
        
        return(contentType: resultContentType, typeFile: resultTypeFile, iconName: resultIconName)
    }
 }
