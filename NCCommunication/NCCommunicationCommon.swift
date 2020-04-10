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
    let k_nextcloud_18: Int = 18
    let k_encodeCharacterSet = " #;?@&=$+{}<>,!'*"
    
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
    
    @objc public func setup(webDavRoot: String, davRoot: String) {
        
        self.webDavRoot = webDavRoot
        self.davRoot = davRoot
        
        if webDavRoot.first == "/" { self.webDavRoot = String(self.webDavRoot.dropFirst()) }
        if webDavRoot.last == "/" { self.webDavRoot = String(self.webDavRoot.dropLast()) }
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
        
        let allowedCharacterSet = (CharacterSet(charactersIn: k_encodeCharacterSet).inverted)
        if let escapedString = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {            
            var url: URLConvertible
            do {
                try url = escapedString.asURL()
                return url
            } catch _ {
                return nil
            }
        }
        return nil
    }
    
    func encodeString(_ string: String) -> String? {
        
        let allowedCharacterSet = (CharacterSet(charactersIn: k_encodeCharacterSet).inverted)
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
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
 }
