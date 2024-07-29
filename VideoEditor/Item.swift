//
//  Item.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
