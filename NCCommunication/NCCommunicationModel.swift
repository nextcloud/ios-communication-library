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
import MobileCoreServices
import SwiftyXMLParser
import SwiftyJSON

//MARK: - File

@objc public class NCCommunicationActivity: NSObject {
    
    @objc public var app = ""
    @objc public var date = NSDate()
    @objc public var idActivity: Int = 0
    @objc public var icon = ""
    @objc public var link = ""
    @objc public var message = ""
    @objc public var message_rich: Data?
    @objc public var object_id: Int = 0
    @objc public var object_name = ""
    @objc public var object_type = ""
    @objc public var previews: Data?
    @objc public var subject = ""
    @objc public var subject_rich: Data?
    @objc public var type = ""
    @objc public var user = ""
}

@objc public class NCCommunicationEditorDetailsCreators: NSObject {
    
    @objc public var editor = ""
    @objc public var ext = ""
    @objc public var identifier = ""
    @objc public var mimetype = ""
    @objc public var name = ""
    @objc public var templates: Int = 0
}

@objc public class NCCommunicationEditorDetailsEditors: NSObject {
    
    @objc public var mimetypes = [String]()
    @objc public var name = ""
    @objc public var optionalMimetypes = [String]()
    @objc public var secure: Int = 0
}

@objc public class NCCommunicationEditorTemplates: NSObject {
    
    @objc public var delete = ""
    @objc public var ext = ""
    @objc public var identifier = ""
    @objc public var name = ""
    @objc public var preview = ""
    @objc public var type = ""
}

@objc public class NCCommunicationExternalSite: NSObject {
    
    @objc public var icon = ""
    @objc public var idExternalSite: Int = 0
    @objc public var lang = ""
    @objc public var name = ""
    @objc public var type = ""
    @objc public var url = ""
}

@objc public class NCCommunicationFile: NSObject {
    
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
    @objc public var iconName = ""
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
    @objc public var typeFile = ""
}

@objc public class NCCommunicationNotifications: NSObject {
    
    @objc public var actions: Data?
    @objc public var app = ""
    @objc public var date = NSDate()
    @objc public var icon: String?
    @objc public var idNotification: Int = 0
    @objc public var link = ""
    @objc public var message = ""
    @objc public var messageRich = ""
    @objc public var messageRichParameters: Data?
    @objc public var objectId = ""
    @objc public var objectType = ""
    @objc public var subject = ""
    @objc public var subjectRich = ""
    @objc public var subjectRichParameters: Data?
    @objc public var user = ""
}


@objc public class NCCommunicationRichdocumentsTemplate: NSObject {

    @objc public var delete = ""
    @objc public var ext = ""
    @objc public var name = ""
    @objc public var preview = ""
    @objc public var templateID: Int = 0
    @objc public var type = ""
}

@objc public class NCCommunicationTrash: NSObject {

    @objc public var contentType = ""
    @objc public var date = NSDate()
    @objc public var directory: Bool = false
    @objc public var fileId = ""
    @objc public var fileName = ""
    @objc public var filePath = ""
    @objc public var hasPreview: Bool = false
    @objc public var iconName = ""
    @objc public var size: Double = 0
    @objc public var typeFile = ""
    @objc public var trashbinFileName = ""
    @objc public var trashbinOriginalLocation = ""
    @objc public var trashbinDeletionTime = NSDate()
}

@objc public class NCCommunicationUserProfile: NSObject {
    
    @objc public var address = ""
    @objc public var backend = ""
    @objc public var backendCapabilitiesSetDisplayName: Bool = false
    @objc public var backendCapabilitiesSetPassword: Bool = false
    @objc public var displayName = ""
    @objc public var email = ""
    @objc public var enabled: Bool = false
    @objc public var groups = [String]()
    @objc public var language = ""
    @objc public var lastLogin: Double = 0
    @objc public var locale = ""
    @objc public var phone = ""
    @objc public var quota: Double = 0
    @objc public var quotaFree: Double = 0
    @objc public var quotaRelative: Double = 0
    @objc public var quotaTotal: Double = 0
    @objc public var quotaUsed: Double = 0
    @objc public var storageLocation = ""
    @objc public var subadmin = [String]()
    @objc public var twitter = ""
    @objc public var userID = ""
    @objc public var webpage = ""
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
    
    let requestBodyTrash =
    """
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\" xmlns:nc=\"http://nextcloud.org/ns\">
        <d:prop>
            <d:displayname />
            <d:getcontenttype />
            <d:resourcetype />
            <d:getcontentlength />
            <d:getlastmodified />
            <d:creationdate />
            <d:getetag />
            <d:quota-used-bytes />
            <d:quota-available-bytes />
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
    </d:propfind>
    """
    
    func convertDataAppPassword(data: Data) -> String? {
        
        let xml = XML.parse(data)
        return xml["ocs", "data", "apppassword"].text        
    }
    
    func convertDataFile(data: Data, showHiddenFiles: Bool) -> [NCCommunicationFile] {
        
        var files = [NCCommunicationFile]()
        let webDavRoot = "/" + NCCommunicationCommon.shared.webDavRoot + "/"
        let davRootFiles = "/" + NCCommunicationCommon.shared.davRoot + "/files/"
        guard let baseUrl = NCCommunicationCommon.shared.getHostName(urlString: NCCommunicationCommon.shared.url) else {
            return files
        }
        
        let xml = XML.parse(data)
        let elements = xml["d:multistatus", "d:response"]
        for element in elements {
            let file = NCCommunicationFile()
            if let href = element["d:href"].text {
                var fileNamePath = href
                
                if href.last == "/" {
                    fileNamePath = String(href.dropLast())
                }
                
                // path
                file.path = (fileNamePath as NSString).deletingLastPathComponent + "/"
                file.path = file.path.removingPercentEncoding ?? ""
                
                // fileName
                file.fileName = (fileNamePath as NSString).lastPathComponent
                file.fileName = file.fileName.removingPercentEncoding ?? ""
                if file.fileName.first == "." && !showHiddenFiles { continue }
              
                // ServerUrl
                if href.hasSuffix(webDavRoot) {
                    file.fileName = "."
                    file.serverUrl = ".."
                } else if file.path.contains(webDavRoot) {
                    file.serverUrl = baseUrl + file.path.dropLast()
                } else if file.path.contains(davRootFiles + NCCommunicationCommon.shared.user) {
                    let postUrl = file.path.replacingOccurrences(of: davRootFiles + NCCommunicationCommon.shared.user, with: webDavRoot.dropLast())
                    file.serverUrl = baseUrl + postUrl.dropLast()
                } else if file.path.contains(davRootFiles + NCCommunicationCommon.shared.userId) {
                    let postUrl = file.path.replacingOccurrences(of: davRootFiles + NCCommunicationCommon.shared.userId, with: webDavRoot.dropLast())
                    file.serverUrl = baseUrl + postUrl.dropLast()
                }
                file.serverUrl = file.serverUrl.removingPercentEncoding ?? ""
            }
            
            let propstat = element["d:propstat"][0]
                        
            if let getlastmodified = propstat["d:prop", "d:getlastmodified"].text {
                if let date = NCCommunicationCommon.shared.convertDate(getlastmodified, format: "EEE, dd MMM y HH:mm:ss zzz") {
                    file.date = date
                }
            }
            
            if let creationdate = propstat["d:prop", "d:creationdate"].text {
                if let date = NCCommunicationCommon.shared.convertDate(creationdate, format: "EEE, dd MMM y HH:mm:ss zzz") {
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
                file.contentType = "httpd/unix-directory"
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
                        
            if let encrypted = propstat["d:prop", "nc:is-encrypted"].text {
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
            
            let results = NCCommunicationCommon.shared.getInternalContenType(fileName: file.fileName, contentType: file.contentType, directory: file.directory)
            
            file.contentType = results.contentType
            file.typeFile = results.typeFile
            file.iconName = results.iconName
            
            files.append(file)
        }
        
        return files
    }
    
    func convertDataTrash(data: Data, showHiddenFiles: Bool) -> [NCCommunicationTrash] {
        
        var files = [NCCommunicationTrash]()
        var first: Bool = true
    
        let xml = XML.parse(data)
        let elements = xml["d:multistatus", "d:response"]
        for element in elements {
            if first {
                first = false
                continue
            }
            let file = NCCommunicationTrash()
            if let href = element["d:href"].text {
                var fileNamePath = href
                
                if href.last == "/" {
                    fileNamePath = String(href.dropLast())
                }
                
                // path
                file.filePath = (fileNamePath as NSString).deletingLastPathComponent + "/"
                file.filePath = file.filePath.removingPercentEncoding ?? ""
                
                // fileName
                file.fileName = (fileNamePath as NSString).lastPathComponent
                file.fileName = file.fileName.removingPercentEncoding ?? ""
            }
            
            let propstat = element["d:propstat"][0]
                        
            if let getlastmodified = propstat["d:prop", "d:getlastmodified"].text {
                if let date = NCCommunicationCommon.shared.convertDate(getlastmodified, format: "EEE, dd MMM y HH:mm:ss zzz") {
                    file.date = date
                }
            }
            
            if let getcontenttype = propstat["d:prop", "d:getcontenttype"].text {
                file.contentType = getcontenttype
            }
            
            let resourcetypeElement = propstat["d:prop", "d:resourcetype"]
            if resourcetypeElement["d:collection"].error == nil {
                file.directory = true
                file.contentType = "httpd/unix-directory"
            }
            
            if let fileId = propstat["d:prop", "oc:fileid"].text {
                file.fileId = fileId
            }
            
            if let haspreview = propstat["d:prop", "nc:has-preview"].text {
                file.hasPreview = (haspreview as NSString).boolValue
            }
            
            if let size = propstat["d:prop", "oc:size"].text {
                file.size = Double(size) ?? 0
            }
            
            if let trashbinFileName = propstat["d:prop", "nc:trashbin-filename"].text {
                file.trashbinFileName = trashbinFileName
            }
            
            if let trashbinOriginalLocation = propstat["d:prop", "nc:trashbin-original-location"].text {
                file.trashbinOriginalLocation = trashbinOriginalLocation
            }
            
            if let trashbinDeletionTime = propstat["d:prop", "nc:trashbin-deletion-time"].text {
                if let trashbinDeletionTimeDouble = Double(trashbinDeletionTime) {
                    file.trashbinDeletionTime = Date.init(timeIntervalSince1970: trashbinDeletionTimeDouble) as NSDate
                }
            }

            let results = NCCommunicationCommon.shared.getInternalContenType(fileName: file.fileName, contentType: file.contentType, directory: file.directory)
            
            file.contentType = results.contentType
            file.typeFile = results.typeFile
            file.iconName = results.iconName
            
            files.append(file)
        }
        
        return files
    }
}

