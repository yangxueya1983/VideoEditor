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
    var cacheKey: String = ""
    var transitionType: TransitionType = TransitionType.None
    @Transient var image: UIImage = UIImage()
    @Transient var duration: CMTime = .positiveInfinity
    
    var url: URL {
        return PicStorage.shared.cachePathForKey(key: cacheKey)
    }
    
    init(cacheKey: String, image: UIImage, duration: CMTime = CMTime(value: 3, timescale: 1), transitionType: TransitionType = TransitionType.None) {
        self.cacheKey = cacheKey
        self.image = image
        self.duration = duration
    }
}

@Model
class AudioItem {
    var itemID: UUID = UUID()
    var cacheKey: String = ""
    @Transient var selectRange: CMTimeRange = CMTimeRange(start: .zero, duration: .positiveInfinity)
    @Transient var positionTime: CMTime = .zero
    
    var url: URL {
        return PicStorage.shared.cachePathForKey(key: cacheKey)
    }
    
    init(cacheKey: String, selectRange: CMTimeRange, positionTime: CMTime) {
        self.cacheKey = cacheKey
        self.selectRange = selectRange
        self.positionTime = positionTime
    }
}

//enum TransitionType:String, CaseIterable, Identifiable, Codable {
//    case None = "None"
//    case TranslateUp = "TranslateUp"
//    case ScaleUp = "ScaleUp"
//    case Opacity = "Opacity"
//    
//    
//    var id:String {self.rawValue}
//    
//    var thumbImgName:String {
//        switch self {
//        case .None: return "avatar0"
//        case .TranslateUp: return "avatar1"
//        case .ScaleUp: return "avatar2"
//        case .Opacity: return "avatar3"
//        }
//    }
//}

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

