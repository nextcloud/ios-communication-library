//
//  NCCommunicationError.swift
//  Nextcloud
//
//  Created by Henrik Storch on 06/12/21.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
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
import SwiftyXMLParser

@objcMembers
public class NCCError: NSObject {

    static let internalError = -9999

    public let errorCode: Int
    public let errorDescription: String

    static let urlError = NCCError(errorCode: NSURLErrorBadURL, errorDescription: NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
    static let xmlError = NCCError(errorCode: NSURLErrorBadServerResponse, errorDescription: NSLocalizedString("_error_decode_xml_", value: "Invalid response, error decoding XML", comment: ""))
    static let invalidDate = NCCError(errorCode: NSURLErrorBadServerResponse, errorDescription: NSLocalizedString("_invalid_date_format_", value: "Invalid date format", comment: ""))
    static let invalidData = NCCError(errorCode: NSURLErrorCannotDecodeContentData, errorDescription: NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: ""))

    public static let success = NCCError(errorCode: 0, errorDescription: "")

    private static func getErrorDescription(for code: Int) -> String? {
        switch code {
        case -9999:
            return NSLocalizedString("_internal_server_", value: "Internal error", comment: "")
        case -1001:
            return NSLocalizedString("_time_out_", value: "Time out", comment: "")
        case -1004:
            return NSLocalizedString("_server_down_", value: "The server appears to be down", comment: "")
        case -1005:
            return NSLocalizedString("_not_possible_connect_to_server_", value: "It is not possible to connect to the server at this time", comment: "")
        case -1009:
            return NSLocalizedString("_not_connected_internet_", value: "Server connection error", comment: "")
        case -1011:
            return NSLocalizedString("_error_", value: "Generic error", comment: "")
        case -1012:
            return NSLocalizedString("_not_possible_connect_to_server_", value: "It is not possible to connect to the server at this time", comment: "")
        case -1013:
            return NSLocalizedString("_user_authentication_required_", value: "User authentication required", comment: "")
        case -1200:
            return NSLocalizedString("_ssl_connection_error_", value: "Connection SSL error, try again", comment: "")
        case -1202:
            return NSLocalizedString("_ssl_certificate_untrusted_", value: "The certificate for this server is invalid", comment: "")
        case 0: return ""
        case 101:
            return NSLocalizedString("_forbidden_characters_from_server_", value: "The name contains at least one invalid character", comment: "")
        case 304:
            return NSLocalizedString("_error_not_modified_", value: "Resource not modified", comment: "")
        case 400:
            return NSLocalizedString("_bad_request_", value: "Bad request", comment: "")
        case 401:
            return NSLocalizedString("_unauthorized_", value: "Unauthorized", comment: "")
        case 403:
            return NSLocalizedString("_error_not_permission_", value: "You don't have permission to complete the operation", comment: "")
        case 404:
            return NSLocalizedString("_error_not_found_", value: "The requested resource could not be found", comment: "")
        case 405:
            return NSLocalizedString("_method_not_allowed_", value: "The requested method is not supported", comment: "")
        case 409:
            return NSLocalizedString("_error_conflict_", value: "The request could not be completed due to a conflict with the current state of the resource", comment: "")
        case 412:
            return NSLocalizedString("_error_precondition_", value: "The server does not meet one of the preconditions that the requester", comment: "")
        case 413:
            return NSLocalizedString("_request_entity_too_large_", value: "The file is too large", comment: "")
        case 423:
            return NSLocalizedString("_webdav_locked_", value: "WebDAV Locked: Trying to access locked resource", comment: "")
        case 500:
            return NSLocalizedString("_internal_server_", value: "Internal server error", comment: "")
        case 503:
            return NSLocalizedString("_server_error_retry_", value: "The server is temporarily unavailable", comment: "")
        case 507:
            return NSLocalizedString("_user_over_quota_", value: "Storage quota is reached", comment: "")
        case 200:
            return NSLocalizedString("_transfer_stopped_", value: "Transfer stopped", comment: "")
        case 207:
            return NSLocalizedString("_error_multi_status_", value: "WebDAV multistatus", comment: "")
        default:
            return nil
        }
    }

    public init(errorCode: Int, errorDescription: String) {
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }

    init(error: Error) {
        errorCode = error._code
        errorDescription = error.localizedDescription
    }

    init(nsError: NSError) {
        errorCode = nsError.code
        errorDescription = nsError.localizedDescription
    }

    init(rootJson: JSON) {
        let statuscode = rootJson["ocs"]["meta"]["statuscode"].int ?? NCCError.internalError
        errorCode = 200..<300 ~= statuscode ? 0 : statuscode
        if let errorMsg = rootJson["ocs"]["meta"]["message"].string {
            errorDescription = errorMsg
        } else {
            errorDescription = NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
        }
    }

    init(statusCode: Int, fallbackDescription: String) {
        self.errorCode = statusCode
        self.errorDescription = "\(statusCode): " + (NCCError.getErrorDescription(for: statusCode) ?? fallbackDescription)
    }

    convenience init(httpResponse: HTTPURLResponse) {
        self.init(statusCode: httpResponse.statusCode, fallbackDescription: httpResponse.description)
    }

    init(xmlData: Data) {
        let xml = XML.parse(xmlData)
        let statuscode = xml["ocs", "meta", "statuscode"].int ?? NCCError.internalError
        errorCode = 200..<300 ~= statuscode ? 0 : statuscode
        errorDescription = xml["ocs", "meta", "message"].text ?? xml["d:error"]["s:message"].text ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
    }

    convenience init<T: AFResponse>(error: AFError?, afResponse: T) {
        if let errorCode = afResponse.response?.statusCode {
            guard let dataResponse = afResponse as? Alamofire.DataResponse<T.Success, T.Failure>,
                  let errorData = dataResponse.data
            else {
                self.init(statusCode: errorCode, fallbackDescription: afResponse.response?.description ?? "")
                return
            }

            if let errorJson = try? JSON(data: errorData) {
                self.init(rootJson: errorJson)
            } else if let data = dataResponse.data {
                self.init(xmlData: data)
            } else {
                self.init(statusCode: errorCode, fallbackDescription: "")
            }

        } else if let error = error {
            switch error {
            case .createUploadableFailed(let error as NSError):
                self.init(nsError: error)
            case .createURLRequestFailed(let error as NSError):
                self.init(nsError: error)
            case .requestAdaptationFailed(let error as NSError):
                self.init(nsError: error)
            case .sessionInvalidated(let error as NSError):
                self.init(nsError: error)
            case .sessionTaskFailed(let error as NSError):
                self.init(nsError: error)
            default :
                self.init(error: error)
            }
        } else {
            self.init(errorCode: 0, errorDescription: "")
        }
    }
}


public protocol AFResponse {
    associatedtype Failure: Error
    associatedtype Success

    var response: HTTPURLResponse? { get }
    var error: Failure? { get }
}

extension AFDownloadResponse: AFResponse { }
extension AFDataResponse: AFResponse { }
