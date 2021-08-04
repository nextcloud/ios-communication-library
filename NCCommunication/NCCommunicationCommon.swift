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
    
    @objc optional func authenticationChallenge(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    @objc optional func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    
    @objc optional func networkReachabilityObserver(_ typeReachability: NCCommunicationCommon.typeReachability)
    
    @objc optional func downloadProgress(_ progress: Float, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func uploadProgress(_ progress: Float, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
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
    var webDav: String = "remote.php/dav"
    
    var cookies: [String:[HTTPCookie]] = [:]
    var internalUTI: [UTTypeConformsToServer] = []

    var delegate: NCCommunicationCommonDelegate?
    
    @objc public let sessionIdentifierDownload: String = "com.nextcloud.session.download"
    @objc public let sessionIdentifierUpload: String = "com.nextcloud.session.upload"

    @objc public enum typeReachability: Int {
        case unknown = 0
        case notReachable = 1
        case reachableEthernetOrWiFi = 2
        case reachableCellular = 3
    }
    
    public enum typeClassFile: String {
        case audio = "audio"
        case compress = "compress"
        case directory = "directory"
        case document = "document"
        case image = "image"
        case unknow = "unknow"
        case video = "video"
    }
    
    public enum typeIconFile: String {
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

    public struct UTTypeConformsToServer {
        var UTIString: String
        var classFile: String
        var iconName: String
        var name: String
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
        super.init()
        
        _filenamePathLog = _pathLog + "/" + _filenameLog
        loadingInternalUTI()
    }
    
    //MARK: - Setup
    
    @objc public func setup(account: String? = nil, user: String, userId: String, password: String, urlBase: String, userAgent: String, webDav: String?, nextcloudVersion: Int, delegate: NCCommunicationCommonDelegate?) {
        
        self.setup(account:account, user: user, userId: userId, password: password, urlBase: urlBase)
        self.setup(userAgent: userAgent)
        if (webDav != nil) { self.setup(webDav: webDav!) }
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
    
    @objc public func setup(nextcloudVersion: Int) {
        
        self.nextcloudVersion = nextcloudVersion
    }
    
    //MARK: -
    
    @objc public func remove(account: String) {
        
        cookies[account] = nil
    }
        
    //MARK: -  UTI
    
    internal func loadingInternalUTI() {
        
        internalUTI = []

        // markdown
        addInternalUTI(UTIString: "net.daringfireball.markdown", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.document.rawValue, name: "markdown")
        // text
        addInternalUTI(UTIString: "org.oasis-open.opendocument.text", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.document.rawValue, name: "document")
        addInternalUTI(UTIString: "org.openxmlformats.wordprocessingml.document", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.document.rawValue, name: "document")
        addInternalUTI(UTIString: "com.microsoft.word.doc", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.document.rawValue, name: "document")
        addInternalUTI(UTIString: "com.apple.iwork.pages.pages", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.document.rawValue, name: "pages")
        // sheet
        addInternalUTI(UTIString: "org.oasis-open.opendocument.spreadsheet", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.xls.rawValue, name: "sheet")
        addInternalUTI(UTIString: "org.openxmlformats.spreadsheetml.sheet", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.xls.rawValue, name: "sheet")
        addInternalUTI(UTIString: "com.microsoft.excel.xls", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.xls.rawValue, name: "sheet")
        addInternalUTI(UTIString: "com.apple.iwork.numbers.numbers", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.xls.rawValue, name: "numbers")
        // presentation
        addInternalUTI(UTIString: "org.oasis-open.opendocument.presentation", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.ppt.rawValue, name: "presentation")
        addInternalUTI(UTIString: "org.openxmlformats.presentationml.presentation", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.ppt.rawValue, name: "presentation")
        addInternalUTI(UTIString: "com.microsoft.powerpoint.ppt", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.ppt.rawValue, name: "presentation")
        addInternalUTI(UTIString: "com.apple.iwork.keynote.key", classFile: typeClassFile.document.rawValue, iconName: typeIconFile.ppt.rawValue, name: "keynote")
    }
    
    @objc public func addInternalUTI(UTIString: String, classFile: String, iconName: String, name: String) {
        
        if !internalUTI.contains(where: { $0.UTIString == UTIString }) {
            let newUTI = UTTypeConformsToServer.init(UTIString: UTIString, classFile: classFile, iconName: iconName, name: name)
            internalUTI.append(newUTI)
        }
    }
    
    @objc public func objcGetInternalType(fileName: String, mimeType: String, directory: Bool) -> [String: String] {
                
        let results = getInternalType(fileName: fileName , mimeType: mimeType, directory: directory)
        
        return ["mimeType":results.mimeType, "classFile":results.classFile, "iconName":results.iconName, "UTI":results.UTI, "fileNameWithoutExt":results.fileNameWithoutExt, "ext":results.ext]
    }

    public func getInternalType(fileName: String, mimeType: String, directory: Bool) -> (mimeType: String, classFile: String, iconName: String, UTI: String, fileNameWithoutExt: String, ext: String) {
        
        var ext = (fileName as NSString).pathExtension.lowercased()
        var mimeType = mimeType
        var classFile = "", iconName = "", UTIString = "", fileNameWithoutExt = ""
        
        // UTI
        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil) {
            let inUTI = unmanagedFileUTI.takeRetainedValue()
            fileNameWithoutExt = (fileName as NSString).deletingPathExtension
            
            // contentType detect
            if mimeType == "" {
                if let mimeUTI = UTTypeCopyPreferredTagWithClass(inUTI, kUTTagClassMIMEType) {
                    mimeType = mimeUTI.takeRetainedValue() as String
                }
            }
            
            // TypeIdentifier
            UTIString = inUTI as String

            if directory {
                mimeType = "httpd/unix-directory"
                classFile = typeClassFile.directory.rawValue
                iconName = typeIconFile.directory.rawValue
                UTIString = kUTTypeFolder as String
                fileNameWithoutExt = fileName
                ext = ""
            } else {
                let result = getFileProperties(inUTI: inUTI)
                classFile = result.classFile
                iconName = result.iconName
            }
        }
        
        return(mimeType: mimeType, classFile: classFile, iconName: iconName, UTI: UTIString, fileNameWithoutExt: fileNameWithoutExt, ext: ext)
    }
    
    public func getFileProperties(inUTI: CFString) -> (classFile: String, iconName: String, name: String, ext: String) {
    
        var classFile: String = ""
        var iconName: String = ""
        var name: String = ""
        var ext: String = ""
        let inUTIString: String = inUTI as String
        
        if let fileExtension = UTTypeCopyPreferredTagWithClass(inUTI as CFString, kUTTagClassFilenameExtension) {
            ext = String(fileExtension.takeRetainedValue())
        }
        
        if UTTypeConformsTo(inUTI, kUTTypeImage) {
            classFile = typeClassFile.image.rawValue
            iconName = typeIconFile.image.rawValue
            name = "image"
        } else if UTTypeConformsTo(inUTI, kUTTypeMovie) {
            classFile = typeClassFile.video.rawValue
            iconName = typeIconFile.movie.rawValue
            name = "movie"
        } else if UTTypeConformsTo(inUTI, kUTTypeAudio) {
            classFile = typeClassFile.audio.rawValue
            iconName = typeIconFile.audio.rawValue
            name = "audio"
        } else if UTTypeConformsTo(inUTI, kUTTypeZipArchive) {
            classFile = typeClassFile.compress.rawValue
            iconName = typeIconFile.compress.rawValue
            name = "archive"
        } else if UTTypeConformsTo(inUTI, kUTTypeHTML) {
            classFile = typeClassFile.document.rawValue
            iconName = typeIconFile.code.rawValue
            name = "code"
        } else if UTTypeConformsTo(inUTI, kUTTypePDF) {
            classFile = typeClassFile.document.rawValue
            iconName = typeIconFile.pdf.rawValue
            name = "document"
        } else if UTTypeConformsTo(inUTI, kUTTypeRTF) {
            classFile = typeClassFile.document.rawValue
            iconName = typeIconFile.txt.rawValue
            name = "document"
        } else if UTTypeConformsTo(inUTI, kUTTypeText) {
            if ext == "" { ext = "txt" }
            classFile = typeClassFile.document.rawValue
            iconName = typeIconFile.txt.rawValue
            name = "text"
        } else {
            if let result = internalUTI.first(where: {$0.UTIString == inUTIString}) {
                return(result.classFile, result.iconName, result.name, ext)
            } else {
                if UTTypeConformsTo(inUTI, kUTTypeContent) {
                    classFile = typeClassFile.document.rawValue
                    iconName = typeIconFile.document.rawValue
                    name = "document"
                } else {
                    classFile = typeClassFile.unknow.rawValue
                    iconName = typeIconFile.unknow.rawValue
                    name = "file"
                }
            }
        }
        
        return(classFile, iconName, name, ext)
    }
    
    //MARK: -  Common public
    
    @objc public func chunkedFile(path: String, fileName: String, outPath: String, sizeInMB: Int) -> [String]? {
           
        var outFilesName: [String] = []
        
        do {
            
            let data = try Data(contentsOf: URL(fileURLWithPath: path + "/" + fileName))
            let dataLen = data.count
            if dataLen == 0 { return nil }
            let chunkSize = ((1024 * 1000) * sizeInMB)
            if chunkSize == 0 { return nil }
            let fullChunks = Int(dataLen / chunkSize)
            let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
                
            for chunkCounter in 0..<totalChunks {
                
                let chunkBase = chunkCounter * chunkSize
                var diff = chunkSize
                if chunkCounter == totalChunks - 1 {
                    diff = dataLen - chunkBase
                }
                    
                let range:Range<Data.Index> = chunkBase..<(chunkBase + diff)
                let chunk = data.subdata(in: range)
                                
                let outFileName = fileName + "." + String(format: "%010d", chunkCounter)
                try chunk.write(to: URL(fileURLWithPath: outPath + "/" + outFileName))
                outFilesName.append(outFileName)
            }
            
        } catch {
            
            return nil
        }
        
        return outFilesName
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
