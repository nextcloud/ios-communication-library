//
//  NCCommunication+NCText.swift
//  Nextcloud
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

    @objc public func NCTextObtainEditorDetails(serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _  editors: [NCEditorDetailsEditors], _ creators: [NCEditorDetailsCreators], _ errorCode: Int, _ errorDescription: String?) -> Void) {
        
        var editors = [NCEditorDetailsEditors]()
        var creators = [NCEditorDetailsCreators]()

        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing?format=json"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, editors, creators, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, editors, creators ,error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let ocsdataeditors = json["ocs"]["data"]["editors"]
                for (_, subJson):(String, JSON) in ocsdataeditors {
                    let editor = NCEditorDetailsEditors()
                    
                    if let mimetypes = subJson["mimetypes"].array {
                        for mimetype in mimetypes {
                            editor.mimetypes.append(mimetype.string ?? "")
                        }
                    }
                    if let name = subJson["name"].string { editor.name = name }
                    if let optionalMimetypes = subJson["optionalMimetypes"].array {
                        for optionalMimetype in optionalMimetypes {
                            editor.optionalMimetypes.append(optionalMimetype.string ?? "")
                        }
                    }
                    if let secure = subJson["secure"].int { editor.secure = secure }
                    
                    editors.append(editor)
                }
                
                let ocsdatacreators = json["ocs"]["data"]["creators"]
                for (_, subJson):(String, JSON) in ocsdatacreators {
                    let creator = NCEditorDetailsCreators()
                    
                    if let editor = subJson["editor"].string { creator.editor = editor }
                    if let ext = subJson["extension"].string { creator.ext = ext }
                    if let identifier = subJson["id"].string { creator.identifier = identifier }
                    if let mimetype = subJson["mimetype"].string { creator.mimetype = mimetype }
                    if let name = subJson["name"].string { creator.name = name }
                    if let templates = subJson["templates"].int { creator.templates = templates }

                    creators.append(creator)
                }
                
                completionHandler(account, editors, creators, 0, nil)
            }
        }
    }
    
    @objc public func NCTextOpenFile(serverUrl: String, fileNamePath: String, editor: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
                
        guard let fileNamePath = NCCommunicationCommon.sharedInstance.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/open?path=/" + fileNamePath + "&editorId=" + editor + "&format=json"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
    
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let url = json["ocs"]["data"]["url"].string
                completionHandler(account, url, 0, nil)
            }
        }
    }
    
    @objc public func NCTextGetListOfTemplates(serverUrl: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _  templates: [NCEditorTemplates], _ errorCode: Int, _ errorDescription: String?) -> Void) {
                
        var templates = [NCEditorTemplates]()

        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/templates/text/textdocumenttemplate?format=json"
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, templates, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, templates, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let ocsdatatemplates = json["ocs"]["data"]["editors"]
                
                for (_, subJson):(String, JSON) in ocsdatatemplates {
                    let template = NCEditorTemplates()
                                   
                    if let identifier = subJson["id"].string { template.identifier = identifier }
                    if let ext = subJson["extension"].string { template.ext = ext }
                    if let name = subJson["name"].string { template.name = name }
                    if let preview = subJson["preview"].string { template.preview = preview }

                    templates.append(template)
                }
                
                completionHandler(account, templates, 0, nil)
            }
        }
    }
    
    @objc public func NCTextCreateFile(serverUrl: String, fileNamePath: String, editorId: String, creatorId: String, templateId: String, customUserAgent: String?, addCustomHeaders: [String:String]?, account: String, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String?) -> Void) {
                
        guard let fileNamePath = NCCommunicationCommon.sharedInstance.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        var endpoint = ""
        
        if templateId == "" {
            endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/create?path=/" + fileNamePath + "&editorId=" + editorId + "&creatorId=" + creatorId + "&format=json"
        } else {
            endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/create?path=/" + fileNamePath + "&editorId=" + editorId + "&creatorId=" + creatorId + "&templateId=" + templateId + "&format=json"
        }
        
        guard let url = NCCommunicationCommon.sharedInstance.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, "Invalid server url")
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        let headers = NCCommunicationCommon.sharedInstance.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description)
            case .success(let json):
                let json = JSON(json)
                let url = json["ocs"]["data"]["url"].string
                completionHandler(account, url, 0, nil)
            }
        }
    }
}
