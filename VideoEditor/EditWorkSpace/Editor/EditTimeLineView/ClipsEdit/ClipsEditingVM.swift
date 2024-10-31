//
//  ClipsEditingVM.swift
//  SwiftUIView
//
//  Created by NancyYang on 2024-09-27.
//

import UIKit
import AVFoundation
import SwiftUI

enum SectionTag: Int, CaseIterable {
    case timeline = 0
    case video = 1
    case audio = 2
}

class ClipEditVM {
    
    var editingInfo:EditingInfo?
    
    var videoClips : [ClipData]
    var audioClips : [ClipData]?
    
    init(videoClips: [ClipData]) {
        self.videoClips = videoClips
    }
    
    func isEditing() -> Bool {
        return editingInfo != nil
    }
    func isEditing(indexPath:IndexPath) -> Bool {
        if let editingInfo {
            return editingInfo.editingIndexPath == indexPath
        }
        return false
    }
    func activeEditing(editInfo:EditingInfo) {
        self.editingInfo = editInfo
    }
    

    func cancelEditing() {
        editingInfo = nil
    }

    func clip(at indexPath:IndexPath) -> ClipData? {
        if indexPath.section == SectionTag.video.rawValue {
            return videoClips[indexPath.row]
        } else if indexPath.section == SectionTag.video.rawValue {
            return audioClips?[indexPath.row]
        } else {
            return nil
        }
    }
    
    
    func numberOfSections() -> Int {
        let count = SectionTag.allCases.count
        return count
    }
        
    func numberOfItemsInSection(section: Int) -> Int {
        if section == SectionTag.timeline.rawValue {
            return 0
        } else if section == SectionTag.video.rawValue {
            return videoClips.count
        } else if section == SectionTag.video.rawValue {
            return audioClips?.count ?? 0
        } else {
            return 0
        }
    }

     
    

}
