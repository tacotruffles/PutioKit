//
//  File.swift
//  Fetch
//
//  Created by Stephen Radford on 22/06/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation
import Alamofire

public final class File: NSObject {
    
    /// The file ID
    public dynamic var id: Int = 0
    
    /// The display name of the file
    public dynamic var name: String?
    
    /// The size of the file in bytes
    public dynamic var size: Int = 0
    
    /// The metatype of file
    public dynamic var contentType: String?
    
    /// Does the file have an MP4?
    public dynamic var hasMP4 = false
    
    /// The ID of the parent folder (if there is one)
    public dynamic var parentID: Int = 0
    
    /// Whether the file has been access or not
    public dynamic var accessed = false
    
    /// URL string of a screenshot
    public dynamic var screenshot: String?
    
    /// Whether the file has been shared with you or if you own it
    public dynamic var isShared = false
    
    /// Seconds that the file should be started from
    public dynamic var startFrom: Float64 = 0
    
    /// Reference to parent file
    public dynamic var parent: File?
    
    /// The timestamp when the file was created
    public dynamic var createdAt: String?
    
    /// Link to an HLS playlist that allows for streaming on Apple devices easily
    public var hlsPlaylist: String? {
        guard let token = Putio.accessToken else { return nil }
        return "\(Router.base)/files/\(id)/hls/media.m3u8?oauth_token=\(token)&subtitle_key=all"
    }
    
    /// Whether the file is a directory or not
    public var isDirectory: Bool {
        guard let type = contentType else { return false }
        return type == "application/x-directory"
    }

    /**
     Create a new File object from JSON retreived from the server
     
     - parameter json: A swiftyJSON Object
     
     - returns: A newly constructed File object
     */
    internal convenience init(json: [String:Any]) {
        self.init()
        id = json["id"] as! Int
        name = json["name"] as? String
        isShared = (json["is_shared"] as? Bool) ?? false
        hasMP4 = (json["is_mp4_available"] as? Bool) ?? false
        parentID = (json["parent_id"] as? Int) ?? 0
        size = (json["size"] as? Int) ?? 0
        contentType = json["content_type"] as? String
        accessed = (json["first_accessed_at"] != nil)
        createdAt = json["created_at"] as? String
        screenshot = json["screenshot"] as? String
    }
    
}

// MARK: - File Methods

extension File {

    
    /// Rename the selected file
    ///
    /// - Parameters:
    ///   - name: The new name of the file
    ///   - completionHandler: The response handler
    public func rename(name: String, completionHandler: @escaping (Bool) -> Void) {
        Putio.request(Router.renameFile(id, name)) { response in
            guard let status = response.response?.statusCode, case 200 ..< 300 = status else {
                completionHandler(false)
                return
            }
            
            completionHandler(true)
        }
    }

    
    /// Get the current progress of the file
    ///
    /// - Parameter completionHandler: The response handler
    public func getProgress(completionHandler: @escaping (Int) -> Void) {
        Putio.request(Router.file(id)) { response in
            guard let status = response.response?.statusCode, case 200 ..< 300 = status else {
                completionHandler(0)
                return
            }
            
            guard let dict = response.result.value as? [String:Any], let file = dict["file"] as? [String:Any] else {
                completionHandler(0)
                return
            }
            
            completionHandler(file["start_from"] as? Int ?? 0)
        }
    }

}

// MARK: - Main Class Methods

extension Putio {
    
    /// Fetch a list of files from the API
    ///
    /// - Parameters:
    ///   - fromParent: The parent to retreive files from. By default this is 0 meaning the root directory.
    ///   - completionHandler: The response handler
    public class func getFiles(fromParent: Int = 0, completionHandler: @escaping ([File]) -> Void) {
        Putio.request(Router.files(fromParent)) { response in
            guard let json = response.result.value as? [String:Any], let files = json["files"] as? [[String:Any]] else {
                completionHandler([])
                return
            }
            
            completionHandler(files.flatMap(File.init))
        }
    }
    
    /// Delete files from the API
    ///
    /// - Parameters:
    ///   - files: The files to delete
    ///   - completionHandler: The response handler
    public class func delete(files: [File], completionHandler: @escaping (Bool) -> Void) {
        let ids = files.map { $0.id }
        Putio.request(Router.deleteFiles(ids)) { response in
            guard let status = response.response?.statusCode, case 200 ..< 300 = status else {
                completionHandler(false)
                return
            }
            
            completionHandler(true)
        }
    }
    
    /// Move the selected files to a new parent directory
    ///
    /// - Parameters:
    ///   - files: The files to move
    ///   - to: The ID of the directory to move files to
    ///   - completionHandler: The response handler
    public class func move(files: [File], to: Int, completionHandler: @escaping (Bool) -> Void) {
        let ids = files.map { $0.id }
        Putio.request(Router.moveFiles(ids, to)) { response in
            guard let status = response.response?.statusCode, case 200 ..< 300 = status else {
                completionHandler(false)
                return
            }
            
            completionHandler(true)
        }
    }
    
}