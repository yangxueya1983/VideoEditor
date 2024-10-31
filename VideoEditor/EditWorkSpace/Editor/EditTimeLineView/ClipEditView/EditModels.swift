//
//  EditModels.swift
//  SwiftUIView
//
//  Created by NancyYang on 2024-10-04.
//

import UIKit
import AVFoundation
import SwiftUI

let kThumbnailSize = CGSize(width: 50, height: 50)
let kDefaultTimeScale:Int32 = 30
let kSecsPerThumbnail = CMTime(seconds: 1, preferredTimescale: kDefaultTimeScale)

class ClipData {
    enum ClipType {
        case video
        case audio
    }

    var id: UUID
    var startTime: CMTime = .zero
    var endTime: CMTime = .zero
    var duration: CMTime
    var type: ClipType

    init(id: UUID = UUID(), duration: CMTime, type: ClipType) {
        self.id = id
        self.duration = duration
        self.type = type
        self.endTime = duration
    }
}

public class EditingInfo {
    enum DragDirection {
        case none
        case left
        case right
    }
    
    var editingIndexPath:IndexPath
    var dragDirection = DragDirection.none
    var editingWidthDiff:CGFloat = 0.0
    var initialFrame:CGRect = CGRectZero
    
    init(editingIndexPath: IndexPath) {
        self.editingIndexPath = editingIndexPath
    }
    
    func isDragging() -> Bool {
        return dragDirection != .none
    }
}
