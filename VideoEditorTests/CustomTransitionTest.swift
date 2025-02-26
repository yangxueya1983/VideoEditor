//
//  CustomTransitionTest.swift
//  VideoEditorTests
//
//  Created by Yu Yang on 2024-08-18.
//

import Foundation
import XCTest
import AVFoundation
import OSLog
@testable import VideoEditor

final class CustomTransitionTest : XCTestCase {
    var transitionDir: URL?
    var video0Name = "video0.mp4"
    var video1Name = "video1.mp4"
    
    
    func createPhotoVideo(imageName: String, outURL: URL) async throws {
//        guard let url = Bundle.main.url(forResource: imageName, withExtension: "jpg") else {
//            return
//        }
//        
//        let duration = CMTime(value: 3, timescale: 1)
//        
//        let imageData = try Data(contentsOf: url)
//        let image = UIImage(data: imageData)
//        
//        let photoItem = PhotoItem(url: url, image: image!, duration: duration)
//
//        let error = await SessionUtilties.concatenatePhotoWithoutTransition(width: 1024, height: 768, photoItems: [photoItem], outURL: outURL)
//        if let error {
//            Logger.viewCycle.debug("create photo video fail with error \(error)")
//        }
    }
    
    override func setUpWithError() throws {
        // create the directory
        let fileManager = FileManager.default
        let dirName = fileManager.temporaryDirectory.appendingPathComponent("CustomTransition", conformingTo: .directory)
        
        Logger.viewCycle.debug("create directory at : \(dirName) ")
        transitionDir = dirName
        
        guard let transitionDir else {
            throw NSError(domain:"create the directory failed", code: 0)
        }
        
        if fileManager.fileExists(atPath: transitionDir.path()) {
            try fileManager.removeItem(at: transitionDir)
        }
        try fileManager.createDirectory(at: transitionDir, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        
    }
    
    func testCustomTransition() async throws {
//        // create the two photo items
//        guard let transitionDir else {
//            return
//        }
//        
//        let url1 = transitionDir.appending(path: video0Name)
//        let url2 = transitionDir.appending(path: video1Name)
//        
//        try await createPhotoVideo(imageName: "pic_1", outURL: url1)
//        try await createPhotoVideo(imageName: "pic_2", outURL: url2)
//        
//        let composition = AVMutableComposition()
//        
//        // track prepartion
//        let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let a1 = AVAsset(url: url1)
//        guard let t1 = try await a1.loadTracks(withMediaType: .video).first else {
//            return
//        }
//        try track1?.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(value:3, timescale: 1)), of: t1, at: .zero)
//        
//        let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let a2 = AVAsset(url: url2)
//        guard let t2 = try await a2.loadTracks(withMediaType: .video).first else {
//            return
//        }
//        try track2?.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(value: 3, timescale: 1)), of: t2, at: .zero)
//        
//        // video composition
//        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
//        // Set the custom compositor class
//        videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
//
//        // Define the instructions for the video composition
//        // TODO: replace the below instruction to check the transition effects
//        let instruction = RadiusDissolveInstruction()
//        instruction.timeRange = CMTimeRange(start: CMTime(value: 0, timescale: 1), duration: CMTime(value:3, timescale: 1))
//
//        // Define layer instructions for the tracks
//        let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.tracks(withMediaType: .video)[0])
//        let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.tracks(withMediaType: .video)[1])
//        layerInstruction1.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: CMTimeRange(start: .zero, end: CMTime(value: 3, timescale: 1)))
//        layerInstruction2.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: CMTimeRange(start: .zero, end: CMTime(value: 3, timescale: 1)))
//
//        instruction.layerInstructions = [layerInstruction1, layerInstruction2]
//        videoComposition.instructions = [instruction]
//
//        // Set frame duration and render size
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
//        videoComposition.renderSize = CGSize(width: 1024, height: 768)
//        
//        // export
//        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality) else {
//            return
//        }
//        
//        let outURL = transitionDir.appending(path: "out.mp4")
//        exportSession.outputURL = outURL
//        exportSession.outputFileType = .mp4
//        exportSession.videoComposition = videoComposition
//        
//        await exportSession.export()
//        switch exportSession.status {
//        case .completed:
//            Logger.viewCycle.debug("succeed")
//        case .failed, .cancelled:
//            Logger.viewCycle.debug("export fail with error: \(String(describing: exportSession.error))")
//        default:
//            Logger.viewCycle.debug("has unknown error")
//        }
        
    }
}

