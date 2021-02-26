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
    @objc optional func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    
    @objc optional func networkReachabilityObserver(_ typeReachability: NCCommunicationCommon.typeReachability)
    
    @objc optional func downloadProgress(_ progress: Double, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func uploadProgress(_ progress: Double, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func downloadComplete(fileName: String, serverUrl: String, etag: String?, date: NSDate?, dateLastModified: NSDate?, length: Int64, description: String?, task: URLSessionTask, errorCode: Int, errorDescription: String)
    @objc optional func uploadComplete(fileName: String, serverUrl: String, ocId: String?, etag: String?, date: NSDate?, size: Int64, description: String?, task: URLSessionTask, errorCode: Int, errorDescription: String)
}

@objc public class NCCommunicationCommon: NSObject {
    @objc public static var shared: NCCommunicationCommon = {
        let instance = NCCommunicationCommon()
        return instance
    }()
    
    var user = ""
    var userId = ""
    var password = ""
    var account = ""
    var urlBase = ""
    var userAgent: String?
    var nextcloudVersion: Int = 0
    var webDav: String = "remote.php/webdav"
    var dav: String = "remote.php/dav"
    
    var cookies: [String:[HTTPCookie]] = [:]

    var delegate: NCCommunicationCommonDelegate?
    
    @objc public let sessionIdentifierDownload: String = "com.nextcloud.session.download"
    @objc public let sessionIdentifierUpload: String = "com.nextcloud.session.upload"

    @objc public enum typeReachability: Int {
        case unknown = 0
        case notReachable = 1
        case reachableEthernetOrWiFi = 2
        case reachableCellular = 3
    }
    
    public enum typeFile: String {
        case audio = "audio"
        case compress = "compress"
        case directory = "directory"
        case document = "document"
        case image = "image"
        case imagemeter = "imagemeter"
        case unknow = "unknow"
        case video = "video"
    }

    private enum iconName: String {
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
    
    private var _filenameLog: String = "communication.log"
    private var _pathLog: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    private var _filenamePathLog: String = ""
    private var _levelLog: Int = 0
    private var _printLog: Bool = true
    private var _copyLogToDocumentDirectory: Bool = false
    
    @objc public var filenameLog: String {
        get {
            return _filenameLog
        }
        set(newVal) {
            if newVal.count > 0 {
                _filenameLog = newVal
                _filenamePathLog = _pathLog + "/" + _filenameLog
            }
        }
    }
    
    @objc public var pathLog: String {
        get {
            return _pathLog
        }
        set(newVal) {
            var tempVal = newVal
            if tempVal.last == "/" {
                tempVal = String(tempVal.dropLast())
            }
            if tempVal.count > 0 {
                _pathLog = tempVal
                _filenamePathLog = _pathLog + "/" + _filenameLog
            }
        }
    }
    
    @objc public var filenamePathLog: String {
        get {
            return _filenamePathLog
        }
    }
    
    @objc public var levelLog: Int {
        get {
            return _levelLog
        }
        set(newVal) {
            _levelLog = newVal
        }
    }
    
    @objc public var printLog: Bool {
        get {
            return _printLog
        }
        set(newVal) {
            _printLog = newVal
        }
    }
    
    @objc public var copyLogToDocumentDirectory: Bool {
        get {
            return _copyLogToDocumentDirectory
        }
        set(newVal) {
            _copyLogToDocumentDirectory = newVal
        }
    }

    //MARK: - Init
    
    override init() {
        _filenamePathLog = _pathLog + "/" + _filenameLog
    }
    
    //MARK: - Setup
    
    @objc public func setup(account: String? = nil, user: String, userId: String, password: String, urlBase: String, userAgent: String, webDav: String?, dav: String?, nextcloudVersion: Int, delegate: NCCommunicationCommonDelegate?) {
        
        self.setup(account:account, user: user, userId: userId, password: password, urlBase: urlBase)
        self.setup(userAgent: userAgent)
        if (webDav != nil) { self.setup(webDav: webDav!) }
        if (dav != nil) { self.setup(dav: dav!) }
        self.setup(nextcloudVersion: nextcloudVersion)
        self.setup(delegate: delegate)
    }
    
    @objc public func setup(account: String? = nil, user: String, userId: String, password: String, urlBase: String) {
        
        if self.account != account {
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: "changeUser"), object: nil)
        }
        
        if account == nil { self.account = "" } else { self.account = account! }
        self.user = user
        self.userId = userId
        self.password = password
        self.urlBase = urlBase
    }
    
    @objc public func setup(delegate: NCCommunicationCommonDelegate?) {
        
        self.delegate = delegate
    }
    
    @objc public func setup(userAgent: String) {
        
        self.userAgent = userAgent
    }
    
    @objc public func setup(webDav: String) {
        
        self.webDav = webDav
        
        if webDav.first == "/" { self.webDav = String(self.webDav.dropFirst()) }
        if webDav.last == "/" { self.webDav = String(self.webDav.dropLast()) }
    }
    
    @objc public func setup(dav: String) {
        
        self.dav = dav
        
        if dav.first == "/" { self.dav = String(self.dav.dropFirst()) }
        if dav.last == "/" { self.dav = String(self.dav.dropLast()) }
    }
    
    @objc public func setup(nextcloudVersion: Int) {
        
        self.nextcloudVersion = nextcloudVersion
    }
    
    //MARK: -
    
    @objc public func remove(account: String) {
        
        cookies[account] = nil
    }
        
    //MARK: -  Common public
    
    @objc public func objcGetInternalType(fileName: String, mimeType: String, directory: Bool) -> [String: String] {
                
        let results = getInternalType(fileName: fileName , mimeType: mimeType, directory: directory)
        
        return ["mimeType":results.mimeType, "typeFile":results.typeFile, "iconName":results.iconName, "uniformTypeIdentifier":results.uniformTypeIdentifier, "fileNameWithoutExt":results.fileNameWithoutExt, "ext":results.ext]
    }

    public func getInternalType(fileName: String, mimeType: String, directory: Bool) -> (mimeType: String, typeFile: String, iconName: String, uniformTypeIdentifier: String, fileNameWithoutExt: String, ext: String) {
        
        var resultMimeType = mimeType
        var resultTypeFile = "", resultIconName = "", resultUniformTypeIdentifier = "", fileNameWithoutExt = "", ext = ""
        
        // UTI
        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (fileName as NSString).pathExtension as CFString, nil) {
            let inUTI = unmanagedFileUTI.takeRetainedValue()
            ext = (fileName as NSString).pathExtension.lowercased()
            fileNameWithoutExt = (fileName as NSString).deletingPathExtension
            
            // contentType detect
            if mimeType == "" {
                if let mimeUTI = UTTypeCopyPreferredTagWithClass(inUTI, kUTTagClassMIMEType) {
                    resultMimeType = mimeUTI.takeRetainedValue() as String
                }
            }
            
            // TypeIdentifier
            resultUniformTypeIdentifier = inUTI as String

            if directory {
                resultMimeType = "httpd/unix-directory"
                resultTypeFile = typeFile.directory.rawValue
                resultIconName = iconName.directory.rawValue
                resultUniformTypeIdentifier = kUTTypeFolder as String
                fileNameWithoutExt = fileName
                ext = ""
            } else if ext == "imi" {
                resultTypeFile = typeFile.imagemeter.rawValue
                resultIconName = iconName.imagemeter.rawValue
            } else {
                let type = getDescriptionFile(inUTI: inUTI)
                resultTypeFile = type.resultTypeFile
                resultIconName = type.resultIconName
            }
        }
        
        return(mimeType: resultMimeType, typeFile: resultTypeFile, iconName: resultIconName, uniformTypeIdentifier: resultUniformTypeIdentifier, fileNameWithoutExt: fileNameWithoutExt, ext: ext)
    }
    
    public func getDescriptionFile(inUTI: CFString) -> (resultTypeFile: String, resultIconName: String, resultFilename: String, resultExtension: String) {
    
        var resultTypeFile: String
        var resultIconName: String
        var resultFileName: String
        var resultExtension: String = ""
        
        if let fileExtension = UTTypeCopyPreferredTagWithClass(inUTI as CFString, kUTTagClassFilenameExtension) {
            resultExtension = String(fileExtension.takeRetainedValue())
        }
        
        if UTTypeConformsTo(inUTI, kUTTypeImage) {
            resultTypeFile = typeFile.image.rawValue
            resultIconName = iconName.image.rawValue
            resultFileName = "image"
        } else if UTTypeConformsTo(inUTI, kUTTypeMovie) {
            resultTypeFile = typeFile.video.rawValue
            resultIconName = iconName.movie.rawValue
            resultFileName = "movie"
        } else if UTTypeConformsTo(inUTI, kUTTypeAudio) {
            resultTypeFile = typeFile.audio.rawValue
            resultIconName = iconName.audio.rawValue
            resultFileName = "audio"
        } else if UTTypeConformsTo(inUTI, kUTTypePDF) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.pdf.rawValue
            resultFileName = "document"
        } else if UTTypeConformsTo(inUTI, kUTTypeRTF) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.txt.rawValue
            resultFileName = "document"
        } else if UTTypeConformsTo(inUTI, kUTTypeText) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.txt.rawValue
            resultFileName = "document"
        } else if UTTypeConformsTo(inUTI, kUTTypeContent) {
            resultTypeFile = typeFile.document.rawValue
            if inUTI as String == "org.openxmlformats.wordprocessingml.document" {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
            } else if inUTI as String == "com.microsoft.word.doc" {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
            } else if inUTI as String == "org.openxmlformats.spreadsheetml.sheet" {
                resultIconName = iconName.xls.rawValue
                resultFileName = "document"
            } else if inUTI as String == "com.microsoft.excel.xls" {
                resultIconName = iconName.xls.rawValue
                resultFileName = "document"
            } else if inUTI as String == "org.openxmlformats.presentationml.presentation" {
                resultIconName = iconName.ppt.rawValue
                resultFileName = "document"
            } else if inUTI as String == "com.microsoft.powerpoint.ppt" {
                resultIconName = iconName.ppt.rawValue
                resultFileName = "document"
            } else if inUTI as String == "public.plain-text" {
                resultIconName = iconName.txt.rawValue
                resultFileName = "document"
            } else if inUTI as String == "public.html" {
                resultIconName = iconName.code.rawValue
                resultFileName = "document"
            } else {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
            }
        } else if UTTypeConformsTo(inUTI, kUTTypeZipArchive) {
            resultTypeFile = typeFile.compress.rawValue
            resultIconName = iconName.compress.rawValue
            resultFileName = "archive"
        } else {
            resultTypeFile = typeFile.unknow.rawValue
            resultIconName = iconName.unknow.rawValue
            resultFileName = "file"
        }
        
        return(resultTypeFile, resultIconName, resultFileName, resultExtension)
    }
    
    //MARK: - Common
        
    func getStandardHeaders(_ appendHeaders: [String: String]?, customUserAgent: String?, e2eToken: String? = nil) -> HTTPHeaders {
        
        return getStandardHeaders(user: user, password: password, appendHeaders: appendHeaders, customUserAgent: customUserAgent, e2eToken: e2eToken)
    }
    
    func getStandardHeaders(user: String, password: String, appendHeaders: [String: String]?, customUserAgent: String?, e2eToken: String? = nil) -> HTTPHeaders {
        
        var headers: HTTPHeaders = [.authorization(username: user, password: password)]
        if customUserAgent != nil {
            headers.update(.userAgent(customUserAgent!))
        } else if let userAgent = userAgent {
            headers.update(.userAgent(userAgent))
        }
        headers.update(.contentType("application/x-www-form-urlencoded"))
        headers.update(name: "OCS-APIRequest", value: "true")
        if e2eToken != nil {
            headers.update(name: "e2e-token", value: e2eToken!)
        }
        
        for (key, value) in appendHeaders ?? [:] {
            headers.update(name: key, value: value)
        }
        
        return headers
    }
    
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
        
        let encodeCharacterSet = " #;?@&=$+{}<>,!'*|%"
        let allowedCharacterSet = (CharacterSet(charactersIn: encodeCharacterSet).inverted)
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
    
    func createStandardUrl(serverUrl: String, endpoint: String) -> URLConvertible? {
        
        guard var serverUrl = encodeString(serverUrl) else { return nil }
        if serverUrl.last != "/" { serverUrl = serverUrl + "/" }
        
        serverUrl = serverUrl + endpoint
        
        return StringToUrl(serverUrl)
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
            if let port = url.port {
                return scheme + "://" + hostName + ":" + String(port)
            }
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
    
    //MARK: - Log

    @objc public func clearFileLog() {

        FileManager.default.createFile(atPath: filenamePathLog, contents: nil, attributes: nil)
        if copyLogToDocumentDirectory {
            let filenameCopyToDocumentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + filenameLog
            FileManager.default.createFile(atPath: filenameCopyToDocumentDirectory, contents: nil, attributes: nil)

        }
    }
    
    @objc public func writeLog(_ text: String?) {
        
        guard let text = text else { return }
        guard let date = NCCommunicationCommon.shared.convertDate(Date(), format: "yyyy-MM-dd' 'HH:mm:ss") else { return }
        let textToWrite = "\(date) " + text + "\n"

        if printLog {
            print(textToWrite)
        }
        
        if levelLog > 0 {
            
            writeLogToDisk(filename: filenamePathLog, text: textToWrite)
           
            if copyLogToDocumentDirectory {
                let filenameCopyToDocumentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + filenameLog
                writeLogToDisk(filename: filenameCopyToDocumentDirectory, text: textToWrite)
            }
        }
    }
    
    private func writeLogToDisk(filename: String, text: String) {
        
        guard let data = text.data(using: .utf8) else { return }
        
        if !FileManager.default.fileExists(atPath: filename) {
            FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil)
        }
        if let fileHandle = FileHandle(forWritingAtPath: filename) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    }
 }
