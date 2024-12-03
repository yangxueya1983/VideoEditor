//
//  Items.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-09.
//

import Foundation
import AVFoundation
import UIKit
import SwiftData


@Model
class PhotoItem {
    var itemID: UUID = UUID()
    var url: URL
    @Transient var image: UIImage = UIImage()
    @Transient var duration: CMTime = .positiveInfinity
    
    init(url: URL, image: UIImage, duration: CMTime) {
        self.url = url
        self.image = image
        self.duration = duration
    }
}

@Model
class AudioItem {
    var itemID: UUID = UUID()
    var url: URL
    @Transient var selectRange: CMTimeRange = CMTimeRange(start: .zero, duration: .positiveInfinity)
    @Transient var positionTime: CMTime = .zero
    
    init(url: URL, selectRange: CMTimeRange, positionTime: CMTime) {
        self.url = url
        self.selectRange = selectRange
        self.positionTime = positionTime
    }
}

enum TransitionType:String, CaseIterable, Identifiable, Codable {
    case None = "None"
    case Translate_Up = "Translate_Up"
    case ScaleUp = "ScaleUp"
    case Opacity = "Opacity"
    
    var id:String {self.rawValue}
    
}

@Model
class TransitionCfg {
    var item1Id: UUID
    var item2Id: UUID
    var type : TransitionType
    @Transient var duration: CMTime = .positiveInfinity
    
    init(item1Id: UUID, item2Id: UUID, type: TransitionType, duration: CMTime) {
        self.item1Id = item1Id
        self.item2Id = item2Id
        self.type = type
        self.duration = duration

    }
}

