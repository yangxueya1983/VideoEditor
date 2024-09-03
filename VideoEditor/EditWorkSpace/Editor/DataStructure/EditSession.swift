//
//  EditSession.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-09.
//

import Foundation
import PhotosUI
import SwiftyJSON

class EditSession: ObservableObject {
    let id = UUID().uuidString
    @Published var photoItems: [PhotoItem] = []
    @Published var audioItems: [AudioItem] = []
    @Published var transitions: [TransitionCfg] = []

    var videoWidth: Int = 1080
    var videoHeight: Int = 1920
    
    func loadWithImages(images:[UIImage]) -> Bool {
        return true
    }

    func hasPhoto() -> Bool {
        return photoItems.count > 0
    }
    
    func hasTransition() -> Bool {
        if transitions.isEmpty {
            return false
        }
        
        for t in transitions {
            if t.type != .None {
                return true
            }
        }

        return false
    }
    
    func isValid() -> Bool {
        return true
    }
    
    func check() -> Bool {
        // TODO: implement this
        
        // TODO: audio timerange should have no overlap
        return true
    }
    
    func groupPhotoItemsWithoutTransition() -> ([[PhotoItem]], [TransitionCfg]) {
        var groups: [[PhotoItem]] = []
        var trans: [TransitionCfg] = []
        
        var oneGroup: [PhotoItem] = []
        for itm in photoItems {
            if oneGroup.isEmpty {
                oneGroup.append(itm)
                continue
            }
            
            assert(!oneGroup.isEmpty)
            let prvItem = oneGroup.last!
            let cfg = findTransitionType(item1: prvItem, item2: itm)
            guard let cfg = cfg else {
                assert(false, "the transition type can not be found")
            }
            
            if cfg.type == .None {
                oneGroup.append(itm)
            } else {
                groups.append(oneGroup)
                oneGroup.removeAll()
                trans.append(cfg)
                oneGroup.append(itm)
            }
        }
        
        if !oneGroup.isEmpty {
            groups.append(oneGroup)
            oneGroup.removeAll()
        }
        
        return (groups, trans)
    }
    
    
    private func findTransitionType(item1: PhotoItem, item2: PhotoItem) -> TransitionCfg? {
        let id1 = item1.id
        let id2 = item2.id
        
        for itm in transitions {
            if itm.item1Id == id1 && itm.item2Id == id2 {
                return itm
            }
        }
        
        return nil
    }
    
}
