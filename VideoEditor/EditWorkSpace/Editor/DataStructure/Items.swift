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
    let image: UIImage
    let duration: CMTime
}

struct AudioItem {
    let url: URL
    var selectRange: CMTimeRange
    var positionTime: CMTime
}

enum TransitionType {
    case None
    case Translate_Up
    case ScaleUp
    case Opacity
}

struct TransitionCfg {
    let item1Id: UUID
    let item2Id: UUID
    let type : TransitionType = .None
    let duration: CMTime
}

struct TextItem {
    var attrStr: AttributedString
    var rect: CGRect
}

