//
//  FileManager.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-23.
//

import Foundation


class WorkspaceManager {
    static let rootFolderName: String = "VideoEditor"
    static let draftFolderName: String = "Draft"
    static let draftFileName: String = "drafts.json"
    //static let draftFileName: String = "drafts"
    
    // Shared instance
    static let shared = WorkspaceManager()
 
    var sessionDraftArray:[EditSession] = []
    
    private init() {
//        try? FileManager.default.createDirectory(at: WorkspaceManager.getNewWorkspaceDirectory(), withIntermediateDirectories: true)
        
        //load local
    }
    

    

    
    func addNewDraft(session:EditSession) -> Bool {
        sessionDraftArray.append(session)
        return true
    }
    
    func loadDrafts() -> Bool {
        let fileURL = WorkspaceManager.getDraftsFileURL()
        let data = try? Data(contentsOf: fileURL)
        if let data {

        }
        return false
    }
    
    func saveDrafts() -> Bool {
        let fileURL = WorkspaceManager.getDraftsFileURL()

        return true
    }
    
    static func getNewWorkspaceDirectory() -> URL {
        let url = URL.documentsDirectory
        return url.appending(components: rootFolderName, draftFolderName, directoryHint: .isDirectory)
    }
    
    static func getDraftsFileURL() -> URL {
        let dirURL = getNewWorkspaceDirectory()
        return dirURL.appending(path: draftFileName)
    }
}
