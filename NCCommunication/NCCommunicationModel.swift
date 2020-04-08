//
//  NCCommunicationModel.swift
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
import SwiftyXMLParser

//MARK: - File

@objc public class NCFile: NSObject {
    
    @objc public var commentsUnread: Bool = false
    @objc public var contentType = ""
    @objc public var creationDate = NSDate()
    @objc public var date = NSDate()
    @objc public var directory: Bool = false
    @objc public var e2eEncrypted: Bool = false
    @objc public var etag = ""
    @objc public var favorite: Bool = false
    @objc public var fileId = ""
    @objc public var fileName = ""
    @objc public var hasPreview: Bool = false
    @objc public var mountType = ""
    @objc public var ocId = ""
    @objc public var ownerId = ""
    @objc public var ownerDisplayName = ""
    @objc public var path = ""
    @objc public var permissions = ""
    @objc public var quotaUsedBytes: Double = 0
    @objc public var quotaAvailableBytes: Double = 0
    @objc public var resourceType = ""
    @objc public var richWorkspace = ""
    @objc public var size: Double = 0
    @objc public var serverUrl = ""
    @objc public var trashbinFileName = ""
    @objc public var trashbinOriginalLocation = ""
    @objc public var trashbinDeletionTime = NSDate()
}

@objc public class NCExternalFile: NSObject {
    
    @objc public var idExternalSite: Int = 0
    @objc public var name = ""
    @objc public var url = ""
    @objc public var lang = ""
    @objc public var icon = ""
    @objc public var type = ""
}

@objc public class NCEditorDetailsEditors: NSObject {
    
    @objc public var mimetypes = [String]()
    @objc public var name = ""
    @objc public var optionalMimetypes = [String]()
    @objc public var secure: Int = 0
}

@objc public class NCEditorDetailsCreators: NSObject {
    
    @objc public var editor = ""
    @objc public var ext = ""
    @objc public var identifier = ""
    @objc public var mimetype = ""
    @objc public var name = ""
    @objc public var templates: Int = 0
}

@objc public class NCEditorTemplates: NSObject {
    
    @objc public var identifier = ""
    @objc public var delete = ""
    @objc public var ext = ""
    @objc public var name = ""
    @objc public var preview = ""
    @objc public var type = ""
}

//MARK: - Data File

class NCDataFileXML: NSObject {

    let requestBodyFile =
    """
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\" xmlns:nc=\"http://nextcloud.org/ns\">
        <d:prop>
            <d:getlastmodified />
            <d:getetag />
            <d:getcontenttype />
            <d:resourcetype />
            <d:quota-available-bytes />
            <d:quota-used-bytes />
            <d:creationdate />

            <permissions xmlns=\"http://owncloud.org/ns\"/>
            <id xmlns=\"http://owncloud.org/ns\"/>
            <fileid xmlns=\"http://owncloud.org/ns\"/>
            <size xmlns=\"http://owncloud.org/ns\"/>
            <favorite xmlns=\"http://owncloud.org/ns\"/>
            <share-types xmlns=\"http://owncloud.org/ns\"/>
            <owner-id xmlns=\"http://owncloud.org/ns\"/>
            <owner-display-name xmlns=\"http://owncloud.org/ns\"/>
            <comments-unread xmlns=\"http://owncloud.org/ns\"/>

            <is-encrypted xmlns=\"http://nextcloud.org/ns\"/>
            <has-preview xmlns=\"http://nextcloud.org/ns\"/>
            <mount-type xmlns=\"http://nextcloud.org/ns\"/>
            <rich-workspace xmlns=\"http://nextcloud.org/ns\"/>
        </d:prop>
    </d:propfind>
    """
    
    let requestBodyFileSetFavorite =
    """
    <?xml version=\"1.0\"?>
    <d:propertyupdate xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">
        <d:set>
            <d:prop>
                <oc:favorite>%i</oc:favorite>
            </d:prop>
        </d:set>
    </d:propertyupdate>
    """
    
    let requestBodyFileListingFavorites =
    """
    <?xml version=\"1.0\"?>
    <oc:filter-files xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\" xmlns:nc=\"http://nextcloud.org/ns\">
        <d:prop>
            <d:getlastmodified />
            <d:getetag />
            <d:getcontenttype />
            <d:resourcetype />
            <d:quota-available-bytes />
            <d:quota-used-bytes />
            <d:creationdate />

            <permissions xmlns=\"http://owncloud.org/ns\"/>
            <id xmlns=\"http://owncloud.org/ns\"/>
            <fileid xmlns=\"http://owncloud.org/ns\"/>
            <size xmlns=\"http://owncloud.org/ns\"/>
            <favorite xmlns=\"http://owncloud.org/ns\"/>
            <share-types xmlns=\"http://owncloud.org/ns\"/>
            <owner-id xmlns=\"http://owncloud.org/ns\"/>
            <owner-display-name xmlns=\"http://owncloud.org/ns\"/>
            <comments-unread xmlns=\"http://owncloud.org/ns\"/>

            <is-encrypted xmlns=\"http://nextcloud.org/ns\"/>
            <has-preview xmlns=\"http://nextcloud.org/ns\"/>
            <mount-type xmlns=\"http://nextcloud.org/ns\"/>
            <rich-workspace xmlns=\"http://nextcloud.org/ns\"/>
        </d:prop>
        <oc:filter-rules>
            <oc:favorite>1</oc:favorite>
        </oc:filter-rules>
    </oc:filter-files>
    """
    
    let requestBodySearchFileName =
    """
    <?xml version=\"1.0\"?>
    <d:searchrequest xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\" xmlns:nc=\"http://nextcloud.org/ns\">
    <d:basicsearch>
        <d:select>
            <d:prop>
                <d:displayname/>
                <d:getcontenttype/>
                <d:resourcetype/>
                <d:getcontentlength/>
                <d:getlastmodified/>
                <d:creationdate/>
                <d:getetag/>
                <d:quota-used-bytes/>
                <d:quota-available-bytes/>
                <permissions xmlns=\"http://owncloud.org/ns\"/>
                <id xmlns=\"http://owncloud.org/ns\"/>
                <fileid xmlns=\"http://owncloud.org/ns\"/>
                <size xmlns=\"http://owncloud.org/ns\"/>
                <favorite xmlns=\"http://owncloud.org/ns\"/>
                <is-encrypted xmlns=\"http://nextcloud.org/ns\"/>
                <mount-type xmlns=\"http://nextcloud.org/ns\"/>
                <owner-id xmlns=\"http://owncloud.org/ns\"/>
                <owner-display-name xmlns=\"http://owncloud.org/ns\"/>
                <comments-unread xmlns=\"http://owncloud.org/ns\"/>
                <has-preview xmlns=\"http://nextcloud.org/ns\"/>
                <trashbin-filename xmlns=\"http://nextcloud.org/ns\"/>
                <trashbin-original-location xmlns=\"http://nextcloud.org/ns\"/>
                <trashbin-deletion-time xmlns=\"http://nextcloud.org/ns\"/>
            </d:prop>
        </d:select>
    <d:from>
        <d:scope>
            <d:href>%@</d:href>
            <d:depth>%@</d:depth>
        </d:scope>
    </d:from>
    <d:where>
        <d:like>
            <d:prop>
                <d:displayname/>
            </d:prop>
            <d:literal>%@</d:literal>
        </d:like>
    </d:where>
    </d:basicsearch>
    </d:searchrequest>
    """
    
    let requestBodySearchMedia =
    """
    <?xml version=\"1.0\"?>
    <d:searchrequest xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\" xmlns:nc=\"http://nextcloud.org/ns\">
      <d:basicsearch>
        <d:select>
          <d:prop>
            <d:displayname/>
            <d:getcontenttype/>
            <d:resourcetype/>
            <d:getcontentlength/>
            <d:getlastmodified/>
            <d:creationdate/>
            <d:getetag/>
            <d:quota-used-bytes/>
            <d:quota-available-bytes/>
            <permissions xmlns=\"http://owncloud.org/ns\"/>
            <id xmlns=\"http://owncloud.org/ns\"/>
            <fileid xmlns=\"http://owncloud.org/ns\"/>
            <size xmlns=\"http://owncloud.org/ns\"/>
            <favorite xmlns=\"http://owncloud.org/ns\"/>
            <is-encrypted xmlns=\"http://nextcloud.org/ns\"/>
            <mount-type xmlns=\"http://nextcloud.org/ns\"/>
            <owner-id xmlns=\"http://owncloud.org/ns\"/>
            <owner-display-name xmlns=\"http://owncloud.org/ns\"/>
            <comments-unread xmlns=\"http://owncloud.org/ns\"/>
            <has-preview xmlns=\"http://nextcloud.org/ns\"/>
            <trashbin-filename xmlns=\"http://nextcloud.org/ns\"/>
            <trashbin-original-location xmlns=\"http://nextcloud.org/ns\"/>
            <trashbin-deletion-time xmlns=\"http://nextcloud.org/ns\"/>
          </d:prop>
        </d:select>
        <d:from>
          <d:scope>
            <d:href>%@</d:href>
            <d:depth>infinity</d:depth>
          </d:scope>
        </d:from>
        <d:orderby>
          <d:order>
            <d:prop>
              <d:getlastmodified/>
            </d:prop>
            <d:descending/>
          </d:order>
          <d:order>
            <d:prop>
              <d:displayname/>
            </d:prop>
            <d:descending/>
          </d:order>
        </d:orderby>
        <d:where>
          <d:and>
            <d:or>
              <d:like>
                <d:prop>
                  <d:getcontenttype/>
                </d:prop>
                <d:literal>image/%%</d:literal>
              </d:like>
              <d:like>
                <d:prop>
                  <d:getcontenttype/>
                </d:prop>
                <d:literal>video/%%</d:literal>
              </d:like>
            </d:or>
            <d:or>
              <d:and>
                <d:lte>
                  <d:prop>
                    <d:getlastmodified/>
                  </d:prop>
                  <d:literal>%@</d:literal>
                </d:lte>
                <d:gte>
                  <d:prop>
                    <d:getlastmodified/>
                  </d:prop>
                  <d:literal>%@</d:literal>
                </d:gte>
              </d:and>
            </d:or>
          </d:and>
        </d:where>
      </d:basicsearch>
    </d:searchrequest>
    """
    
    func convertDataFile(data: Data, checkFirstFileOfList: Bool) -> [NCFile] {
        
        var files = [NCFile]()
        var isNotFirstFileOfList: Bool = false
        
        if checkFirstFileOfList == false { isNotFirstFileOfList = true }

        let xml = XML.parse(data)
        let elements = xml["d:multistatus", "d:response"]
        for element in elements {
            let file = NCFile()
            if let href = element["d:href"].text {
                var fileNamePath = href
                // directory
                if href.last == "/" {
                    fileNamePath = String(href[..<href.index(before: href.endIndex)])
                    file.directory = true
                }
                // path
                file.path = (fileNamePath as NSString).deletingLastPathComponent + "/"
                file.path = file.path.removingPercentEncoding ?? ""
                // fileName
                if isNotFirstFileOfList {
                    file.fileName = (fileNamePath as NSString).lastPathComponent
                    file.fileName = file.fileName.removingPercentEncoding ?? ""
                } else {
                    file.fileName = ""
                }
                if href == "/remote.php/webdav/" {
                    file.serverUrl = ".."
                    file.fileName = "."
                } else {
                    file.serverUrl = NCCommunicationCommon.sharedInstance.url + file.path.replacingOccurrences(of: "dav/files/"+NCCommunicationCommon.sharedInstance.user, with: "webdav").dropLast()
                }
            }
            let propstat = element["d:propstat"][0]
                        
            // d:
            
            if let getlastmodified = propstat["d:prop", "d:getlastmodified"].text {
                if let date = NCCommunicationCommon.sharedInstance.convertDate(getlastmodified, format: "EEE, dd MMM y HH:mm:ss zzz") {
                    file.date = date
                }
            }
            if let creationdate = propstat["d:prop", "d:creationdate"].text {
                if let date = NCCommunicationCommon.sharedInstance.convertDate(creationdate, format: "EEE, dd MMM y HH:mm:ss zzz") {
                    file.creationDate = date
                }
            }
            if let getetag = propstat["d:prop", "d:getetag"].text {
                file.etag = getetag.replacingOccurrences(of: "\"", with: "")
            }
            if let getcontenttype = propstat["d:prop", "d:getcontenttype"].text {
                file.contentType = getcontenttype
            }
            let resourcetypeElement = propstat["d:prop", "d:resourcetype"]
            if resourcetypeElement["d:collection"].error == nil {
                file.directory = true
            } else {
                if let resourcetype = propstat["d:prop", "d:resourcetype"].text {
                    file.resourceType = resourcetype
                }
            }
            if let quotaavailablebytes = propstat["d:prop", "d:quota-available-bytes"].text {
                file.quotaAvailableBytes = Double(quotaavailablebytes) ?? 0
            }
            if let quotausedbytes = propstat["d:prop", "d:quota-used-bytes"].text {
                file.quotaUsedBytes = Double(quotausedbytes) ?? 0
            }
            
            // oc:
           
            if let permissions = propstat["d:prop", "oc:permissions"].text {
                file.permissions = permissions
            }
            if let ocId = propstat["d:prop", "oc:id"].text {
                file.ocId = ocId
            }
            if let fileId = propstat["d:prop", "oc:fileid"].text {
                file.fileId = fileId
            }
            if let size = propstat["d:prop", "oc:size"].text {
                file.size = Double(size) ?? 0
            }
            if let favorite = propstat["d:prop", "oc:favorite"].text {
                file.favorite = (favorite as NSString).boolValue
            }
            if let ownerid = propstat["d:prop", "oc:owner-id"].text {
                file.ownerId = ownerid
            }
            if let ownerdisplayname = propstat["d:prop", "oc:owner-display-name"].text {
                file.ownerDisplayName = ownerdisplayname
            }
            if let commentsunread = propstat["d:prop", "oc:comments-unread"].text {
                file.commentsUnread = (commentsunread as NSString).boolValue
            }
            
            // nc:
            
            if let encrypted = propstat["d:prop", "nc:encrypted"].text {
                file.e2eEncrypted = (encrypted as NSString).boolValue
            }
            if let haspreview = propstat["d:prop", "nc:has-preview"].text {
                file.hasPreview = (haspreview as NSString).boolValue
            }
            if let mounttype = propstat["d:prop", "nc:mount-type"].text {
                file.mountType = mounttype
            }
            if let richWorkspace = propstat["d:prop", "nc:rich-workspace"].text {
                file.richWorkspace = richWorkspace
            }
            isNotFirstFileOfList = true;
            files.append(file)
        }
        
        return files
    }
}

