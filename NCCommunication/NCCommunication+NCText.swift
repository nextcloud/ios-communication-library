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

    @objc public func NCTextObtainEditorDetails(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _  editors: [NCCommunicationEditorDetailsEditors], _ creators: [NCCommunicationEditorDetailsCreators], _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let account = NCCommunicationCommon.shared.account
        var editors = [NCCommunicationEditorDetailsEditors]()
        var creators = [NCCommunicationEditorDetailsCreators]()

        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, editors, creators, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, editors, creators ,error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let ocsdataeditors = json["ocs"]["data"]["editors"]
                for (_, subJson):(String, JSON) in ocsdataeditors {
                    let editor = NCCommunicationEditorDetailsEditors()
                    
                    if let mimetypes = subJson["mimetypes"].array {
                        for mimetype in mimetypes {
                            editor.mimetypes.append(mimetype.stringValue)
                        }
                    }
                    editor.name = subJson["name"].stringValue
                    if let optionalMimetypes = subJson["optionalMimetypes"].array {
                        for optionalMimetype in optionalMimetypes {
                            editor.optionalMimetypes.append(optionalMimetype.stringValue)
                        }
                    }
                    editor.secure = subJson["secure"].intValue
                    editors.append(editor)
                }
                
                let ocsdatacreators = json["ocs"]["data"]["creators"]
                for (_, subJson):(String, JSON) in ocsdatacreators {
                    let creator = NCCommunicationEditorDetailsCreators()
                    
                    creator.editor = subJson["editor"].stringValue
                    creator.ext = subJson["extension"].stringValue
                    creator.identifier = subJson["id"].stringValue
                    creator.mimetype = subJson["mimetype"].stringValue
                    creator.name = subJson["name"].stringValue
                    creator.templates = subJson["templates"].intValue

                    creators.append(creator)
                }
                
                completionHandler(account, editors, creators, 0, "")
            }
        }
    }
    
    @objc public func NCTextOpenFile(fileNamePath: String, editor: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _  url: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account

        guard let fileNamePath = NCCommunicationCommon.shared.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/open?path=/" + fileNamePath + "&editorId=" + editor + "&format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
    
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let url = json["ocs"]["data"]["url"].stringValue
                completionHandler(account, url, 0, "")
            }
        }
    }
    
    @objc public func NCTextGetListOfTemplates(customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _  templates: [NCCommunicationEditorTemplates], _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account
        var templates = [NCCommunicationEditorTemplates]()

        let endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/templates/text/textdocumenttemplate?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, templates, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, templates, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let ocsdatatemplates = json["ocs"]["data"]["editors"]
                
                for (_, subJson):(String, JSON) in ocsdatatemplates {
                    let template = NCCommunicationEditorTemplates()
                    
                    template.ext = subJson["extension"].stringValue
                    template.identifier = subJson["id"].stringValue
                    template.name = subJson["name"].stringValue
                    template.preview = subJson["preview"].stringValue
                    
                    templates.append(template)
                }
                
                completionHandler(account, templates, 0, "")
            }
        }
    }
    
    @objc public func NCTextCreateFile(fileNamePath: String, editorId: String, creatorId: String, templateId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, completionHandler: @escaping (_ account: String, _ url: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
                
        let account = NCCommunicationCommon.shared.account

        guard let fileNamePath = NCCommunicationCommon.shared.encodeString(fileNamePath) else {
            completionHandler(account, nil, NSURLErrorUnsupportedURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        var endpoint = ""
        
        if templateId == "" {
            endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/create?path=/" + fileNamePath + "&editorId=" + editorId + "&creatorId=" + creatorId + "&format=json"
        } else {
            endpoint = "ocs/v2.php/apps/files/api/v1/directEditing/create?path=/" + fileNamePath + "&editorId=" + editorId + "&creatorId=" + creatorId + "&templateId=" + templateId + "&format=json"
        }
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.url, endpoint: endpoint) else {
            completionHandler(account, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                completionHandler(account, nil, error.errorCode, error.description ?? "")
            case .success(let json):
                let json = JSON(json)
                let url = json["ocs"]["data"]["url"].stringValue
                completionHandler(account, url, 0, "")
            }
        }
    }
}
