//
//  Extension.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-28.
//

import Foundation
import AVFoundation

//extension CMTime: Codable {
//    enum CodingKeys: String, CodingKey {
//        case value, timescale, flags, epoch
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(value, forKey: .value)
//        try container.encode(timescale, forKey: .timescale)
//        try container.encode(flags.rawValue, forKey: .flags)
//        try container.encode(epoch, forKey: .epoch)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let value = try container.decode(Int64.self, forKey: .value)
//        let timescale = try container.decode(Int32.self, forKey: .timescale)
//        let flags = try container.decode(CMTimeFlags.self, forKey: .flags)
//        let epoch = try container.decode(Int64.self, forKey: .epoch)
//        self = CMTime(value: value, timescale: timescale, flags: flags, epoch: epoch)
//    }
//}
