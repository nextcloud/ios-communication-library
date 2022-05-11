//
//  NCCommunication+FilesLock.swift
//  NCCommunication
//
//  Created by Henrik Storch on 23.03.22.
//  Copyright © 2022 Henrik Sorch. All rights reserved.
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

extension NCCommunication {

    // available in NC >= 24
    @objc public func lockUnlockFile(serverUrlFileName: String, shouldLock: Bool, options: NCCRequestOptions = NCCRequestOptions(), completionHandler: @escaping (_ errorCode: Int, _ errorDescription: String) -> Void) {

        guard let url = serverUrlFileName.encodedToUrl
        else {
            options.queue.async {
                completionHandler(NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            }
            return
        }

        let method = HTTPMethod(rawValue: shouldLock ? "LOCK" : "UNLOCK")

        var headers = NCCommunicationCommon.shared.getStandardHeaders(options: options)
        headers.update(name: "X-User-Lock", value: "1")

        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)

            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                options.queue.async { completionHandler(error.errorCode, error.description ?? "") }
            case .success:
                options.queue.async { completionHandler(0, "") }
            }
        }
    }
}

