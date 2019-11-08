//
//  NCCommunicationError.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 08/11/19.
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

class NCCommunicationError: NSObject {
   
    func getError(error: AFError?, httResponse: HTTPURLResponse?) -> (errorCode: Int, description: String?) {
        
        if let errorCode = httResponse?.statusCode  {
            switch errorCode {
            case -999:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_internal_server_", value: "", comment: ""))
            case -1001:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_time_out_", value: "", comment: ""))
            case -1004:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_server_down_", value: "", comment: ""))
            case -1005:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_not_possible_connect_to_server_", value: "", comment: ""))
            case -1009:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_not_connected_internet_", value: "Server connection error", comment: ""))
            case -1011:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_error_", value: "Error", comment: ""))
            case -1012:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_not_possible_connect_to_server_", value: "It is not possible to connect to the server at this time", comment: ""))
            case -1013:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_user_authentication_required_", value: "User authentication required", comment: ""))
            case -1200:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_ssl_connection_error_", value: "Connection SSL error, try again", comment: ""))
            case -1202:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_ssl_certificate_untrusted_", value: "The certificate for this server is invalid", comment: ""))
            case 101:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_forbidden_characters_from_server_", value: "The name contains at least one invalid character", comment: ""))
            case 400:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_bad_request_", value: "Bad request", comment: ""))
            case 403:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_error_not_permission_", value: "You don't have permission to complete the operation", comment: ""))
            case 404:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_error_path_", value: "Unable to open this file or folder. Please make sure it exists", comment: ""))
            case 423:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_webdav_locked_", value: "WebDAV Locked: Trying to access locked resource", comment: ""))
            case 500:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_internal_server_", value: "Internal server error", comment: ""))
            case 503:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_server_error_retry_", value: "The server is temporarily unavailable", comment: ""))
            case 507:
                return(errorCode, "\(errorCode): " + NSLocalizedString("_user_over_quota_", value: "Storage quota is reached", comment: ""))
            default:
                return(errorCode, "\(errorCode): " + (httResponse?.description ?? ""))
            }
        }
        
        if let error = error {
            switch error {
            case .createUploadableFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .createURLRequestFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .requestAdaptationFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .sessionInvalidated(let error as NSError):
                return(error.code, error.localizedDescription)
            case .sessionTaskFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            default:
                return(error._code, error.localizedDescription)
            }
        }
        return(0,"")
    }
}
