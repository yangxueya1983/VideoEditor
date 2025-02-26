//
//  VELogger.swift
//  VideoEditor
//
//  Created by NancyYang on 2025-02-26.
//

import OSLog

extension Logger {
    private static var subSystem = Bundle.main.bundleIdentifier ?? "VideoEditor"

    static let veSession = Logger(subsystem: subSystem, category: "VESession")
    
    static let viewCycle = Logger(subsystem: subSystem, category: "ViewCycle")
    static let statistics = Logger(subsystem: subSystem, category: "Statistics")
}
