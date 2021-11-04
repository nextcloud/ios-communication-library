//
//  NCCommunication+Hovercard.swift
//  NCCommunication
//
//  Created by Henrik Storch on 04/11/2021.

//  Copyright © 2021 Henrik Sorch. All rights reserved.
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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

public class Hovercard: NSObject {
    internal init?(jsonData: JSON) {
        guard let userId = jsonData["userId"].string,
              let displayName = jsonData["displayName"].string,
              let actions = jsonData["actions"].array?.compactMap(Action.init)
        else {
            return nil
        }
        self.userId = userId
        self.displayName = displayName
        self.actions = actions
    }
    
    class Action: NSObject {
        internal init?(jsonData: JSON) {
            guard let title = jsonData["title"].string,
                  let icon = jsonData["icon"].string,
                  let hyperlink = jsonData["hyperlink"].string,
                  let appId = jsonData["appId"].string
            else {
                return nil
            }
            self.title = title
            self.icon = icon
            self.hyperlink = hyperlink
            self.appId = appId
        }
        
        let title: String
        let icon: String
        let hyperlink: String
        var hyperlinkUrl: URL? { URL(string: hyperlink) }
        let appId: String
    }
    
    let userId, displayName: String
    let actions: [Action]
}

extension NCCommunication {
    
    // available in NC >= 23 (beta 2)
    @objc public func getHovercard(for userId: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ result: Hovercard?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let endpoint = "ocs/v2.php/hovercard/v1/\(userId)?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint)
        else {
            queue.async {
                completionHandler(nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            }
            return
        }
        
        let method = HTTPMethod(rawValue: "GET")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(nil, error.errorCode, error.description ?? "") }
            case .success(let json):
                let json = JSON(json)
                let data = json["ocs"]["data"]
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                guard statusCode == 200, let result = Hovercard(jsonData: data) else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    queue.async { completionHandler(nil, statusCode, errorDescription) }
                    return
                }
                queue.async {
                    completionHandler(result, 0, "")
                }
            }
        }
    }
}
