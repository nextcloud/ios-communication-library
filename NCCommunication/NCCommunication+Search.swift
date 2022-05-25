//
//  NCCommunication+Search.swift
//  NCCommunication
//
//  Created by Henrik Storch on 26.11.2021.

//  Copyright © 2021 Henrik Storch. All rights reserved.
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

    /// Available NC >= 20
    /// Search many different datasources in the cloud and combine them into one result.
    ///
    /// - Warning: Providers are requested concurrently. Not filtering will result in a high network load.
    ///
    /// - SeeAlso:
    ///  [Nextcloud Search API](https://docs.nextcloud.com/server/latest/developer_manual/digging_deeper/search.html)
    ///
    /// - Parameters:
    ///   - term: The search term
    ///   - options: Additional request options
    ///   - filter: Filter search provider that should be searched. Default is all available provider..
    ///   - update: Callback, notifying that a search provider return its result. Does not include previous results.
    ///   - completion: Callback, notifying that all search providers have been searched. The search is done. Includes all search results.
    @objc public func unifiedSearch(
        term: String,
        options: NCCRequestOptions = NCCRequestOptions(),
        filter: @escaping (NCCSearchProvider) -> Bool = { _ in true },
        update: @escaping (NCCSearchResult?, _ provider: NCCSearchProvider, _ errorCode: Int, _ errorDescription: String) -> Void,
        completion: @escaping ([NCCSearchResult]?, _ errorCode: Int, _ errorDescription: String) -> Void) {
            let endpoint = "ocs/v2.php/search/providers?format=json"
            guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: NCCommunicationCommon.shared.urlBase, endpoint: endpoint) else {
                return completion(nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
            }
            let method = HTTPMethod(rawValue: "GET")
            let headers = NCCommunicationCommon.shared.getStandardHeaders(options: options)

            sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
                debugPrint(response)

                switch response.result {
                case .success(let json):
                    let json = JSON(json)
                    let providerData = json["ocs"]["data"]
                    let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()

                    guard let allProvider = NCCSearchProvider.factory(jsonArray: providerData) else {
                        let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                        return completion(nil, statusCode, errorDescription)
                    }
                    let filteredProviders = allProvider.filter(filter)
                    var searchResult: [NCCSearchResult] = []

                    let group = DispatchGroup()

                    for provider in filteredProviders {
                        group.enter()
                        self.searchProvider(provider.id, term: term, options: options) { partial, errCode, err in
                            update(partial, provider, errCode, err)

                            if let partial = partial {
                                searchResult.append(partial)
                            }
                            group.leave()
                        }
                    }

                    group.notify(queue: options.queue) {
                        completion(searchResult, 0, "")
                    }
                case .failure(let error):
                    let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                    return completion(nil, error.errorCode, error.description ?? "")
                }
            }
        }

    func searchProvider(_ id: String, term: String, options: NCCRequestOptions, completion: @escaping (NCCSearchResult?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        let endpoint = "ocs/v2.php/search/providers/\(id)/search?format=json&term=\(term)"
        guard let url = NCCommunicationCommon.shared.createStandardUrl(
            serverUrl: NCCommunicationCommon.shared.urlBase,
            endpoint: endpoint)
        else {
            return completion(nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: ""))
        }

        let method = HTTPMethod(rawValue: "GET")
        let headers = NCCommunicationCommon.shared.getStandardHeaders(options: options)

        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            switch response.result {
            case .success(let json):
                let json = JSON(json)
                let searchData = json["ocs"]["data"]
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                guard let searchResult = NCCSearchResult(json: searchData) else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    return completion(nil, statusCode, errorDescription)
                }
                completion(searchResult, 0, "")
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                return completion(nil, error.errorCode, error.description ?? "")
            }
        }
    }
}
