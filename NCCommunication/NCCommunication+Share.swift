//
//  NCCommunication+Share.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 15/06/2020.
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
    
    /*
    * @param path           Path to file or folder
    * @param idShare        Identifier of the share to update
    * @param reshares       If set to false (default), only shares owned by the current user are returned.
    *                       If set to true, shares owned by any user from the given file are returned.
    * @param subfiles       If set to false (default), lists only the folder being shared
    *                       If set to true, all shared files within the folder are returned.
    */
    
    @objc public func readShares(reshares: Bool = false, subfiles: Bool = false, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ shares: [NCCommunicationShare]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        readShares(path: nil, idShare: 0, reshares:reshares, subfiles:subfiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, completionHandler: completionHandler)
    }
    
    @objc public func readShares(path: String, reshares: Bool = false, subfiles: Bool = false, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ shares: [NCCommunicationShare]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        readShares(path: path, idShare: 0, reshares:reshares, subfiles:subfiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, completionHandler: completionHandler)
    }
    
    @objc public func readShares(idShare: Int, reshares: Bool = false, subfiles: Bool = false, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ shares: [NCCommunicationShare]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        readShares(path: nil, idShare: idShare, reshares:reshares, subfiles:subfiles, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, completionHandler: completionHandler)
    }
    
    private func readShares(path: String? = nil, idShare: Int = 0, reshares: Bool, subfiles: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ shares: [NCCommunicationShare]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        var endpoint = "ocs/v2.php/apps/files_sharing/api/v1/shares"
        if idShare > 0 {
            endpoint = "ocs/v2.php/apps/files_sharing/api/v1/shares/" + String(idShare)
        }
                
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
             
        var headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        headers.update(.contentType("application/xml"))
        
        var parameters = [
            "reshares": reshares == true ? "true" : "false",
            "subfiles": subfiles == true ? "true" : "false"
        ]
        parameters["path"] = path
    
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseData { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success( _):
                if let data = response.data {
                    let shares = NCDataFileXML().convertDataShare(data: data)
                    if shares.statusCode == 200 {
                        completionHandler(account, shares.shares, 0, "")
                    } else {
                        completionHandler(account, nil, shares.statusCode, shares.message)
                    }
                } else {
                    completionHandler(account, nil, NSURLErrorBadServerResponse, NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decode XML", comment: ""))
                }
            }
        }
    }
        
    /*
    * @param search         The search string
    * @param itemType       The type which is shared (e.g. file or folder)
    * @param shareType      Any of the shareTypes (0 = user; 1 = group; 3 = public link; 6 = federated cloud share)
    * @param page           The page number to be returned (default 1)
    * @param perPage        The number of items per page (default 200)
    */
    
    @objc public func searchSharees(search: String = "", page: Int = 1, perPage: Int = 200, itemType: String = "file", customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ sharees: [NCCommunicationSharee]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/files_sharing/api/v1/sharees?format=json"
                
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        let parameters = [
            "search": search,
            "page": String(page),
            "perPage": String(perPage),
            "itemType": itemType
        ]
    
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
               
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    var sharees: [NCCommunicationSharee] = []
                    for shareType in ["users", "groups", "remotes", "remote_groups", "emails", "circles", "rooms", "lookup"] {
                        for (_, subJson):(String, JSON) in json["ocs"]["data"]["exact"][shareType] {
                            let sharee = NCCommunicationSharee()
                            
                            sharee.label = subJson["label"].stringValue
                            sharee.name = subJson["name"].stringValue
                            sharee.uuid = subJson["uuid"].stringValue
                            sharee.shareType = subJson["value"]["shareType"].intValue
                            sharee.shareWith = subJson["value"]["shareWith"].stringValue
                            
                            sharees.append(sharee)
                        }
                        for (_, subJson):(String, JSON) in json["ocs"]["data"][shareType] {
                            let sharee = NCCommunicationSharee()
                            
                            sharee.label = subJson["label"].stringValue
                            sharee.name = subJson["name"].stringValue
                            sharee.uuid = subJson["uuid"].stringValue
                            sharee.shareType = subJson["value"]["shareType"].intValue
                            sharee.shareWith = subJson["value"]["shareWith"].stringValue
                            
                            sharees.append(sharee)
                        }
                    }
                    completionHandler(account, sharees, 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    /*
    * @param path           path of the file/folder being shared. Mandatory argument
    * @param shareType      0 = user, 1 = group, 3 = Public link. Mandatory argument
    * @param shareWith      User/group ID with who the file should be shared.  This is mandatory for shareType of 0 or 1
    * @param publicUpload   If false (default) public cannot upload to a public shared folder. If true public can upload to a shared folder. Only available for public link shares
    * @param hideDownload   Permission if file can be downloaded via share link (only for single file)
    * @param password       Password to protect a public link share. Only available for public link shares
    * @param permissions    1 - Read only Default for public shares
    *                       2 - Update
    *                       4 - Create
    *                       8 - Delete
    *                       16- Re-share
    *                       31- All above Default for private shares
    *                       For user or group shares.
    *                       To obtain combinations, add the desired values together.
    *                       For instance, for Re-Share, delete, read, update, add 16+8+2+1 = 27.
    */
    
    @objc public func createShareLink(path: String, hideDownload: Bool = false, publicUpload: Bool = false, password: String? = nil, permissions: Int = 1, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ share: NCCommunicationShare?, _ errorCode: Int, _ errorDescription: String) -> Void) {
     
        createShare(path: path, shareType: 3, shareWith: nil, publicUpload: publicUpload, hideDownload: hideDownload, password: password, permissions: permissions, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, completionHandler: completionHandler)
    }
    
    @objc public func createShare(path: String, shareType: Int, shareWith: String, password: String? = nil, permissions: Int = 1, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ share: NCCommunicationShare?, _ errorCode: Int, _ errorDescription: String) -> Void) {
     
        createShare(path: path, shareType: shareType, shareWith: shareWith, publicUpload: false, hideDownload: false, password: password, permissions: permissions, customUserAgent: customUserAgent, addCustomHeaders: addCustomHeaders, completionHandler: completionHandler)
    }
    
    private func createShare(path: String, shareType: Int, shareWith: String?, publicUpload: Bool? = nil, hideDownload: Bool? = nil, password: String? = nil, permissions: Int = 1, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ share: NCCommunicationShare?, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/files_sharing/api/v1/shares?format=json"
                
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        var parameters = [
            "path": path,
            "shareType": String(shareType),
            "permissions": String(permissions)
        ]
        if shareWith != nil {
            parameters["shareWith"] = shareWith!
        }
        if publicUpload != nil {
            parameters["publicUpload"] = publicUpload == true ? "true" : "false"
        }
        if hideDownload != nil {
            parameters["hideDownload"] = hideDownload == true ? "true" : "false"
        }
        if password != nil {
            parameters["password"] = password!
        }
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, self.convertResponseShare(json: json), 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    /*
    * @param idShare        Identifier of the share to update
    * @param password       Password to protect a public link share. Only available for public link shares, Empty string clears the current password, Null results in no update applied to the password
    * @param expireDate
    * @param permissions    1 - Read only Default for public shares
    *                       2 - Update
    *                       4 - Create
    *                       8 - Delete
    *                       16- Re-share
    *                       31- All above Default for private shares
    *                       For user or group shares.
    *                       To obtain combinations, add the desired values together.
    *                       For instance, for Re-Share, delete, read, update, add 16+8+2+1 = 27.
    * @param publicUpload   If false (default) public cannot upload to a public shared folder. If true public can upload to a shared folder. Only available for public link shares
    * @param note           Note
    * @param hideDownload   Permission if file can be downloaded via share link (only for single file)
    */
    
    @objc public func updateShare(idShare: Int, password: String? = nil, expireDate: String? = nil, permissions: Int = 1, publicUpload: Bool = false, note: String? = nil, hideDownload: Bool, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ share: NCCommunicationShare?, _ errorCode: Int, _ errorDescription: String) -> Void) {
           
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/files_sharing/api/v1/shares/" + String(idShare) + "?format=json"

        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "PUT")
             
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)

        var parameters = [
            "permissions": String(permissions)
        ]
        if password != nil {
            parameters["password"] = password
        }
        if expireDate != nil {
            parameters["expireDate"] = expireDate
        }
        if note != nil {
            parameters["note"] = note
        }
        parameters["publicUpload"] = publicUpload == true ? "true" : "false"
        parameters["hideDownload"] = hideDownload == true ? "true" : "false"
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if statusCode == 200 {
                    completionHandler(account, self.convertResponseShare(json: json), 0, "")
                }  else {
                    let errorDescription = json["ocs"]["meta"]["message"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    completionHandler(account, nil, statusCode, errorDescription)
                }
            }
        }
    }
    
    /*
    * @param idShare        Identifier of the share to update
    */
    
    @objc public func deleteShare(idShare: Int, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
              
        let account = NCCommunicationCommon.shared.account
        let endpoint = "ocs/v2.php/apps/files_sharing/api/v1/shares/" + String(idShare)
                   
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
           
        let method = HTTPMethod(rawValue: "DELETE")
                
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
       
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, error.errorCode, error.description ?? "")
            case .success( _):
                completionHandler(account, 0, "")
            }
        }
    }
    
    //MARK: -

    private func convertResponseShare(json: JSON) -> NCCommunicationShare {
        let share = NCCommunicationShare()
                           
        share.canDelete = json["ocs"]["data"]["can_delete"].boolValue
        share.canEdit = json["ocs"]["data"]["can_edit"].boolValue
        share.displaynameFileOwner = json["ocs"]["data"]["displayname_file_owner"].stringValue
        share.displaynameOwner = json["ocs"]["data"]["displayname_owner"].stringValue
        if let value = json["ocs"]["data"]["expiration"].string {
            if let date = NCCommunicationCommon.shared.convertDate(value, format: "YYYY-MM-dd HH:mm:ss") {
                 share.expirationDate = date
            }
        }
        share.fileParent = json["ocs"]["data"]["file_parent"].intValue
        share.fileSource = json["ocs"]["data"]["file_source"].intValue
        share.fileTarget = json["ocs"]["data"]["file_target"].stringValue
        share.hideDownload = json["ocs"]["data"]["hide_download"].boolValue
        share.idShare = json["ocs"]["data"]["id"].intValue
        share.itemSource = json["ocs"]["data"]["item_source"].intValue
        share.itemType = json["ocs"]["data"]["item_type"].stringValue
        share.label = json["ocs"]["data"]["label"].stringValue
        share.mailSend = json["ocs"]["data"]["mail_send"].boolValue
        share.mimeType = json["ocs"]["data"]["mimetype"].stringValue
        share.note = json["ocs"]["data"]["note"].stringValue
        share.parent = json["ocs"]["data"]["parent"].stringValue
        share.password = json["ocs"]["data"]["password"].stringValue
        share.path = json["ocs"]["data"]["path"].stringValue
        share.permissions = json["ocs"]["data"]["permissions"].intValue
        share.sendPasswordByTalk = json["ocs"]["data"]["send_password_by_talk"].boolValue
        share.shareType = json["ocs"]["data"]["share_type"].intValue
        share.shareWith = json["ocs"]["data"]["share_with"].stringValue
        share.shareWithDisplayname = json["ocs"]["data"]["share_with_displayname"].stringValue
        if let stime = json["ocs"]["data"]["stime"].double {
            let date = Date(timeIntervalSince1970: stime) as NSDate
            share.date = date
        }
        share.storage = json["ocs"]["data"]["storage"].intValue
        share.storageId = json["ocs"]["data"]["storage_id"].stringValue
        share.token = json["ocs"]["data"]["token"].stringValue
        share.uidFileOwner = json["ocs"]["data"]["uid_file_owner"].stringValue
        share.uidOwner = json["ocs"]["data"]["uid_owner"].stringValue
        share.url = json["ocs"]["data"]["url"].stringValue

        return share
    }
}
