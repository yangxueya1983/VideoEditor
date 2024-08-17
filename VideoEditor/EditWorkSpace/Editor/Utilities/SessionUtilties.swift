//
//  SessionUtilties.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-09.
//

import Foundation
import AVFoundation
import UIKit

struct CommonUtilities {
    static func imageWithURL(url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
}

struct SessionUtilties {
    static func getAvailableURLs(cnt: Int) throws -> [URL] {
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        
        var ret: [URL] = []
        for _ in 0..<cnt {
            let url = tempDirURL.appendingPathComponent(UUID().uuidString)
            ret.append(url)
        }
        
        return ret
    }
    
    static func concatenatePhotoWithoutTransition(width: Int, height: Int, photoItems:[PhotoItem], outURL: URL) async -> Error?
    {
        let writer = try! AVAssetWriter(url: outURL, fileType: .mov)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        
        // Create a pixel buffer pool
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: bufferAttributes)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)


        var pixelBufferPool = adaptor.pixelBufferPool
        guard let pixelBufferPool else {
            return NSError(domain: "No Pixel buffer pool", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Pixel buffer pool allocated"])
        }
        
        var curTime: CMTime  = .zero
        
        for itm in photoItems {
            guard let image = CommonUtilities.imageWithURL(url: itm.url) else {
                print("image with url \(itm.url) can't be found")
                continue
            }
            // allocate the pixel buffer
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
            
            guard let buffer = pixelBuffer else { continue }
            
            // Draw image on the pixel buffer
            CVPixelBufferLockBaseAddress(buffer, [])
            let pixelData = CVPixelBufferGetBaseAddress(buffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(width), height: Int(height),
                                    bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            
            // wait for the writer input to finish
            while !writerInput.isReadyForMoreMediaData {}
            
            adaptor.append(buffer, withPresentationTime: curTime)
            curTime = CMTimeAdd(curTime, itm.duration)
        }
        
        // TODO: do I need to append the last image twice?
        writerInput.markAsFinished()
        await writer.finishWriting()
        
        if let error = writer.error {
            return error
        } else {
            return nil
        }
    }
    
    private static func concatenatePhotosWithTransition(sess: EditSession, outURL: URL) async throws -> Error? {
        // combine the videos without any transition
        let (groups, transitions) = sess.groupPhotoItemsWithoutTransition()
        assert(groups.count == transitions.count + 1)
        
        let groupsURLs = try getAvailableURLs(cnt: groups.count)
        
        let batchSize = 1
        let totalCnt = groups.count
        let width = sess.videoWidth
        let height = sess.videoHeight
        
        var simpleConcateResults: [Int] = []
        
        for startIndex in stride(from: 0, to: groups.count, by: batchSize) {
            await withTaskGroup(of: Int.self) { group in
                let endIndex = min(startIndex + batchSize, totalCnt)
                
                for i in startIndex..<endIndex {
                    let outURL = groupsURLs[i]
                    group.addTask {
                        let error =  await concatenatePhotoWithoutTransition(width: width, height: height, photoItems: groups[i], outURL: outURL)
                        if let error = error {
                            return 1
                        } else {
                            return 0
                        }
                    }
                }
                
                for await result in group {
                    simpleConcateResults.append(result)
                }
            }
        }
        
        for r in simpleConcateResults {
            if r == 1 {
                return NSError(domain: "Simple concatnate photos failed", code: 0)
            }
        }
        
        // create video assets
        let mixComposition = AVMutableComposition()
        let track1 = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let track2 = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        guard let track1, let track2 else {
            return NSError(domain: "can't create the mutable video track", code: 0)
        }
        
        // alternate two videos tracks
        // there is overlap between two video trackss
        var prevPos : CMTime = .zero
        
        var segmentTimeRanges: [CMTimeRange] = []
        for (idx, url) in groupsURLs.enumerated() {
            let asset = AVAsset(url: url)
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                return NSError(domain: "no video tracks", code: 0)
            }
            
            let duration = try await asset.load(.duration)
            var insertPos = prevPos
            if idx > 0 {
                // previous transition
                let trans = transitions[idx]
                assert(trans.type != .None)
                assert(insertPos > trans.duration)
                insertPos = insertPos - trans.duration
            }
            
            let insertRange = CMTimeRange(start: insertPos, duration: duration)
            if idx % 2 == 0 {
                // insert to track1
                try track1.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: insertPos)
            } else {
                // insert to track2
                try track2.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: insertPos)
            }
            
            segmentTimeRanges.append(insertRange)
            
            prevPos = insertPos + duration
        }
        
        let totalDuration = prevPos
        
        // add instruction for transitions
        let videoCompositions = AVMutableVideoComposition()
        videoCompositions.renderSize = track1.naturalSize
        videoCompositions.frameDuration = CMTime(value: 1, timescale: 30)

        var instructions: [AVMutableVideoCompositionInstruction] = []
        for (idx, _) in groupsURLs.enumerated() {
            var track : AVAssetTrack = idx % 2 == 0 ? track1 : track2
            var prevTrack: AVAssetTrack = idx % 2 == 1 ? track1: track2
            var trackRange = segmentTimeRanges[idx]
            var overlapDur: CMTime = .zero
            var trans: TransitionCfg?
            if idx > 0 {
                trans = transitions[idx-1]
                overlapDur = trans!.duration
                let leftOverlapRange = CMTimeRange(start:trackRange.start,  duration: overlapDur)
                let ins = createTransitionInstruction(curTrack: track, prevTrack: prevTrack, timeRange: leftOverlapRange, trans: trans!)
                instructions.append(contentsOf: ins)
            }
            
            var singleStart = trackRange.start + overlapDur
            var singleDuration = trackRange.duration - overlapDur
            if idx != groupsURLs.count - 1 {
                // not last one, need to consider the right transitions as well
                let rightTrans = transitions[idx]
                let rightTransDur = rightTrans.duration
                singleDuration = singleDuration - rightTransDur
            }
            let ins = createSingleTrackInstruction(curTrack: track, prevTrack: prevTrack, timeRange: CMTimeRange(start: singleStart, duration: singleDuration))
            instructions.append(contentsOf: ins)
        }
        
        videoCompositions.instructions = instructions
        
        if !sess.audioItems.isEmpty {
            // add audio track, make sure the audio item time ranges have no overlap
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            for itm in sess.audioItems {
                let audioAsset = AVAsset(url: itm.url)
                // load audio track
                guard let t = try await audioAsset.loadTracks(withMediaType: .audio).first else {
                    return NSError(domain: "no audio tracks for audio files", code: 0)
                }
                try audioTrack?.insertTimeRange(itm.selectRange, of: t, at: itm.positionTime)
            }
        }
        
        // ready to export
        guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality) else {
            return NSError(domain: "export session error", code: 0)
        }
        
        exportSession.outputURL = outURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoCompositions
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            return nil
        case .failed, .cancelled:
            return exportSession.error
        default:
            // should not happen here
            assert(false)
            break
        }
        
        return NSError(domain: "unknown reason", code: 0)
    }
    
    private static func createTransitionInstruction(curTrack: AVAssetTrack, prevTrack: AVAssetTrack, timeRange: CMTimeRange, trans: TransitionCfg) -> [AVMutableVideoCompositionInstruction] {
        var ret: [AVMutableVideoCompositionInstruction] = []
        
        if trans.type == .Opacity {
            let i1 = AVMutableVideoCompositionInstruction()
            let l1 = AVMutableVideoCompositionLayerInstruction(assetTrack: curTrack)
            l1.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: timeRange)
            i1.layerInstructions = [l1]
            ret.append(i1)
            
            let i2 = AVMutableVideoCompositionInstruction()
            let l2 = AVMutableVideoCompositionLayerInstruction(assetTrack: prevTrack)
            l2.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: timeRange)
            i2.layerInstructions = [l2]
            ret.append(i2)
        } else {
            assert(false, "type \(trans.type) not implemented")
        }
        return ret
    }
    
    private static func createSingleTrackInstruction(curTrack: AVAssetTrack, prevTrack: AVAssetTrack, timeRange: CMTimeRange) -> [AVMutableVideoCompositionInstruction] {
        let i1 = AVMutableVideoCompositionInstruction()
        i1.timeRange = timeRange
        let l1 = AVMutableVideoCompositionLayerInstruction(assetTrack: curTrack)
        l1.setOpacity(1, at: timeRange.start)
        i1.layerInstructions = [l1]
        
        
        let i2 = AVMutableVideoCompositionInstruction()
        i2.timeRange = timeRange
        let l2 = AVMutableVideoCompositionLayerInstruction(assetTrack: prevTrack)
        l2.setOpacity(0, at: timeRange.start)
        i2.layerInstructions = [l2]
        
        return [i1, i2]
    }
    
}
