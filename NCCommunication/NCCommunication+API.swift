//
//  NCCommunication+API.swift
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
    
    @objc public func iosHelper(serverUrl: String, fileNamePath: String, offset: Int, limit: Int, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ files: [NCFile]?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        guard let fileNamePath = NCCommunicationCommon.sharedInstance.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let endpoint = "index.php/apps/ioshelper/api/v1/list?dir=" + fileNamePath + "&offset=\(offset)&limit=\(limit)"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
               
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success(let json):
                var files = [NCFile]()
                let json = JSON(json)
                for (_, subJson):(String, JSON) in json {
                    let file = NCFile()
                    if let modificationDate = subJson["modificationDate"].double {
                        let date = Date(timeIntervalSince1970: modificationDate) as NSDate
                        file.date = date
                    }
                    if let directory = subJson["directory"].bool { file.directory = directory }
                    if let etag = subJson["etag"].string { file.etag = etag }
                    if let favorite = subJson["favorite"].bool { file.favorite = favorite }
                    if let fileId = subJson["fileId"].int { file.fileId = String(fileId) }
                    if let hasPreview = subJson["hasPreview"].bool { file.hasPreview = hasPreview }
                    if let mimetype = subJson["mimetype"].string { file.contentType = mimetype }
                    if let name = subJson["name"].string { file.fileName = name }
                    if let ocId = subJson["ocId"].string { file.ocId = ocId }
                    if let permissions = subJson["permissions"].string { file.permissions = permissions }
                    if let size = subJson["size"].double { file.size = size }
                    files.append(file)
                }
                completionHandler(account, files, 0, nil)
            }
        }
    }
    
    @objc public func downloadPreview(serverUrlPath: String, fileNameLocalPath: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        guard let url = NCCommunicationCommon.sharedInstance.StringToUrl(serverUrlPath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    do {
                        let url = URL.init(fileURLWithPath: fileNameLocalPath)
                        try data.write(to: url, options: .atomic)
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
    
    @objc public func downloadPreview(serverUrl: String, fileNamePath: String, fileNameLocalPath: String, width: Int, height: Int, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        guard let fileNamePath = NCCommunicationCommon.sharedInstance.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        let endpoint = "index.php/core/preview.png?file=" + fileNamePath + "&x=\(width)&y=\(height)&a=1&mode=cover"
            
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    do {
                        let url = URL.init(fileURLWithPath: fileNameLocalPath)
                        try data.write(to: url, options: .atomic)
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
    
    @objc public func downloadPreviewTrash(serverUrl: String, fileId: String, fileNameLocalPath: String, width: Int, height: Int, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        let endpoint = "index.php/apps/files_trashbin/preview?fileId=" + fileId + "&x=\(width)&y=\(height)"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
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
    
    @objc public func getExternalSite(serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ externalFiles: [NCExternalFile], _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        var externalFiles = [NCExternalFile]()

        let endpoint = "ocs/v2.php/apps/external/api/v1?format=json"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, externalFiles, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
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
    
    @objc public func getServerStatus(serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, completionHandler: @escaping (_ serverProductName: String?, _ serverVersion: String? , _ versionMajor: Int, _ versionMinor: Int, _ versionMicro: Int, _ extendedSupport: Bool, _ errorCode: Int, _ errorDescription: String?) -> Void) {
                
        let endpoint = "status.php"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(nil, nil, 0, 0, 0, false, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
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
    
    @objc public func downloadAvatar(serverUrl: String, userID: String, fileNameLocalPath: String, size: Int, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        let endpoint = "index.php/avatar/" + userID + "/\(size)"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
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
    
    @objc public func downloadContent(serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ data: Data?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        guard let url = NCCommunicationCommon.sharedInstance.encodeStringToUrl(serverUrl) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
                
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success( _):
                if let data = response.data {
                    completionHandler(account, data, 0, nil)
                } else {
                    completionHandler(account, nil, NSURLErrorCannotDecodeContentData, "Response error data null")
                }
            }
        }
    }
    
    @objc public func getUserProfile (serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _ userProfile: NCUserProfile?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
    
        let endpoint = "ocs/v2.php/cloud/user?format=json"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case.failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let ocs = json["ocs"]
                let meta = ocs["meta"]
                let data = ocs["data"]
                
                let statusCode = meta["statuscode"].int ?? -999
                
                if statusCode == 200 {
                    
                    let userProfile = NCUserProfile()
                    
                    if let address = data["address"].string { userProfile.address = address }
                    if let backend = data["backend"].string { userProfile.backend = backend }
                                        
                    let backendCapabilities = data["backendCapabilities"]
                    if let setDisplayName = backendCapabilities["setDisplayName"].bool { userProfile.backendCapabilitiesSetDisplayName = setDisplayName }
                    if let setPassword = backendCapabilities["setPassword"].bool { userProfile.backendCapabilitiesSetPassword = setPassword }
                    
                    if let displayName = data["display-name"].string { userProfile.displayName = displayName }
                    if let email = data["email"].string { userProfile.email = email }
                    if let enabled = data["enabled"].bool { userProfile.enabled = enabled }
                    
                    if let groups = data["groups"].array {
                        for group in groups {
                            userProfile.groups.append(group.string ?? "")
                        }
                    }
                    
                    if let userID = data["id"].string { userProfile.userID = userID }
                    if let language = data["language"].string { userProfile.language = language }
                    if let lastLogin = data["lastLogin"].double { userProfile.lastLogin = lastLogin }
                    if let locale = data["locale"].string { userProfile.locale = locale }
                    if let phone = data["phone"].string { userProfile.phone = phone }
                    
                    let quotaJSON = data["quota"]
                    if let free = quotaJSON["free"].double { userProfile.quotaFree = free }
                    if let quota = quotaJSON["quota"].double { userProfile.quota = quota }
                    if let relative = quotaJSON["relative"].double { userProfile.quotaRelative = relative }
                    if let total = quotaJSON["total"].double { userProfile.quotaTotal = total }
                    if let used = quotaJSON["used"].double { userProfile.quotaUsed = used }
                    
                    if let storageLocation = data["storageLocation"].string { userProfile.storageLocation = storageLocation }

                    if let subadmins = data["subadmin"].array {
                        for subadmin in subadmins {
                            userProfile.subadmin.append(subadmin.string ?? "")
                        }
                    }
                    
                    if let twitter = data["twitter"].string { userProfile.twitter = twitter }
                    if let webpage = data["webpage"].string { userProfile.webpage = webpage }
                    
                    completionHandler(account, userProfile, 0, nil)
                    
                } else {
                    
                    let errorDescription = meta["errorDescription"].string ?? "Internal error"
                    
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }

}
