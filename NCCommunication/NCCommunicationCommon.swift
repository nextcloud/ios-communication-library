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
import UIKit
import Alamofire
import MobileCoreServices
import Accelerate

@objc public protocol NCCommunicationCommonDelegate {
    
    @objc optional func authenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    @objc optional func networkReachabilityObserver(_ typeReachability: NCCommunicationCommon.typeReachability)
    
    @objc optional func downloadProgress(_ progress: Int64, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
    @objc optional func uploadProgress(_ progress: Int64, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String, session: URLSession, task: URLSessionTask)
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
    
    private var filenameLog: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/communication.log"
    var levelLog: Int = 0

    //MARK: - Init
    
    override init() {
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
    
    @objc public func objcGetInternalContenType(fileName: String, contentType: String, directory: Bool) -> [String: String] {
                
        let results = getInternalContenType(fileName: fileName , contentType: contentType, directory: directory)
        
        return ["contentType":results.contentType, "typeFile":results.typeFile, "iconName":results.iconName, "typeIdentifier":results.typeIdentifier, "fileNameWithoutExt":results.fileNameWithoutExt, "ext":results.ext]
    }

    public func getInternalContenType(fileName: String, contentType: String, directory: Bool) -> (contentType: String, typeFile: String, iconName: String, typeIdentifier: String, fileNameWithoutExt: String, ext: String) {
        
        var resultContentType = contentType
        var resultTypeFile = "", resultIconName = "", resultTypeIdentifier = "", fileNameWithoutExt = "", ext = ""
        
        // UTI
        if let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (fileName as NSString).pathExtension as CFString, nil) {
            let fileUTI = unmanagedFileUTI.takeRetainedValue()
            ext = (fileName as NSString).pathExtension.lowercased()
            fileNameWithoutExt = (fileName as NSString).deletingPathExtension
            
            // contentType detect
            if contentType == "" {
                if let mimeUTI = UTTypeCopyPreferredTagWithClass(fileUTI, kUTTagClassMIMEType) {
                    resultContentType = mimeUTI.takeRetainedValue() as String
                }
            }
            
            // TypeIdentifier
            resultTypeIdentifier = fileUTI as String

            if directory {
                resultContentType = "httpd/unix-directory"
                resultTypeFile = typeFile.directory.rawValue
                resultIconName = iconName.directory.rawValue
                resultTypeIdentifier = kUTTypeFolder as String
            } else if ext == "imi" {
                resultTypeFile = typeFile.imagemeter.rawValue
                resultIconName = iconName.imagemeter.rawValue
            } else {
                let type = convertUTItoResultType(fileUTI: fileUTI)
                resultTypeFile = type.resultTypeFile
                resultIconName = type.resultIconName
            }
        }
        
        return(contentType: resultContentType, typeFile: resultTypeFile, iconName: resultIconName, typeIdentifier: resultTypeIdentifier, fileNameWithoutExt: fileNameWithoutExt, ext: ext)
    }
    
    public func convertUTItoResultType(fileUTI: CFString) -> (resultTypeFile: String, resultIconName: String, resultFilename: String, resultExtension: String) {
    
        var resultTypeFile: String
        var resultIconName: String
        var resultFileName: String
        var resultExtension: String
        
        if UTTypeConformsTo(fileUTI, kUTTypeImage) {
            resultTypeFile = typeFile.image.rawValue
            resultIconName = iconName.image.rawValue
            resultFileName = "image"
            resultExtension = "jpg"
        } else if UTTypeConformsTo(fileUTI, kUTTypeMovie) {
            resultTypeFile = typeFile.video.rawValue
            resultIconName = iconName.movie.rawValue
            resultFileName = "movie"
            resultExtension = "mov"
        } else if UTTypeConformsTo(fileUTI, kUTTypeAudio) {
            resultTypeFile = typeFile.audio.rawValue
            resultIconName = iconName.audio.rawValue
            resultFileName = "audio"
            resultExtension = "mp3"
        } else if UTTypeConformsTo(fileUTI, kUTTypePDF) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.pdf.rawValue
            resultFileName = "document"
            resultExtension = "pdf"
        } else if UTTypeConformsTo(fileUTI, kUTTypeRTF) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.txt.rawValue
            resultFileName = "document"
            resultExtension = "rtf"
        } else if UTTypeConformsTo(fileUTI, kUTTypeText) {
            resultTypeFile = typeFile.document.rawValue
            resultIconName = iconName.txt.rawValue
            resultFileName = "document"
            resultExtension = "txt"
        } else if UTTypeConformsTo(fileUTI, kUTTypeContent) {
            resultTypeFile = typeFile.document.rawValue
            if fileUTI as String == "org.openxmlformats.wordprocessingml.document" {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
                resultExtension = "docx"
            } else if fileUTI as String == "com.microsoft.word.doc" {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
                resultExtension = "doc"
            } else if fileUTI as String == "org.openxmlformats.spreadsheetml.sheet" {
                resultIconName = iconName.xls.rawValue
                resultFileName = "document"
                resultExtension = "xlsx"
            } else if fileUTI as String == "com.microsoft.excel.xls" {
                resultIconName = iconName.xls.rawValue
                resultFileName = "document"
                resultExtension = "xls"
            } else if fileUTI as String == "org.openxmlformats.presentationml.presentation" {
                resultIconName = iconName.ppt.rawValue
                resultFileName = "document"
                resultExtension = "pptx"
            } else if fileUTI as String == "com.microsoft.powerpoint.ppt" {
                resultIconName = iconName.ppt.rawValue
                resultFileName = "document"
                resultExtension = "ppt"
            } else if fileUTI as String == "public.plain-text" {
                resultIconName = iconName.txt.rawValue
                resultFileName = "document"
                resultExtension = "text"
            } else if fileUTI as String == "public.html" {
                resultIconName = iconName.code.rawValue
                resultFileName = "document"
                resultExtension = "html"
            } else {
                resultIconName = iconName.document.rawValue
                resultFileName = "document"
                resultExtension = ""
            }
        } else if UTTypeConformsTo(fileUTI, kUTTypeZipArchive) {
            resultTypeFile = typeFile.compress.rawValue
            resultIconName = iconName.compress.rawValue
            resultFileName = "archive"
            resultExtension = "zip"
        } else {
            resultTypeFile = typeFile.unknow.rawValue
            resultIconName = iconName.unknow.rawValue
            resultFileName = "file"
            resultExtension = ""
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
    
    func resizeImageUsingVImage(_ image: UIImage, size: CGSize) -> UIImage? {
        
        let cgImage = image.cgImage!
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue), version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
        }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        // create a destination buffer
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = image.cgImage!.bitsPerPixel/8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        // create a CGImage from vImage_Buffer
        var destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }
        // create a UIImage
        let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0.0, orientation: image.imageOrientation) }
        destCGImage = nil
        return resizedImage
    }
    
    //MARK: - Log

    @objc public func setFileLog(level: Int) {
        
        self.levelLog = level
    }
    
    @objc public func getFileNameLog() -> String {
        
        return self.filenameLog
    }
    
    @objc public func setFileNameLog(_ filenameLog: String) {
        
        self.filenameLog = filenameLog
    }
    
    @objc public func clearFileLog() {

        FileManager.default.createFile(atPath: filenameLog, contents: nil, attributes: nil)
    }
    
    @objc public func writeLog(_ text: String?) {
        guard let text = text else { return }
        
        if levelLog > 0 {
            guard let date = NCCommunicationCommon.shared.convertDate(Date(), format: "yyyy-MM-dd' 'HH:mm:ss") else { return }
            let textToWrite = "\(date) " + text + "\n"
            
            guard let data = textToWrite.data(using: .utf8) else { return }
            if !FileManager.default.fileExists(atPath: filenameLog) {
                FileManager.default.createFile(atPath: filenameLog, contents: nil, attributes: nil)
            }            
            if let fileHandle = FileHandle(forWritingAtPath: filenameLog) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
 }
