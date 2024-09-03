//
//  Items.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-09.
//

import Foundation
import AVFoundation
import UIKit

struct PhotoItem {
    let id = UUID()
    let url: URL
    let image: UIImage?
    let duration: CMTime
}

struct AudioItem {
    let url: URL
    var selectRange: CMTimeRange
    var positionTime: CMTime
}

enum TransitionType:String, CaseIterable, Identifiable {
    case None = "None"
    case Translate_Up = "Translate_Up"
    case ScaleUp = "ScaleUp"
    case Opacity = "Opacity"
    
    var id:String {self.rawValue}
    
}

struct TransitionCfg {
    let item1Id: UUID
    let item2Id: UUID
    let type : TransitionType
    let duration: CMTime
}

struct TextItem {
    var attrStr: AttributedString
    var rect: CGRect
}

