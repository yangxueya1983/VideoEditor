//
//  VEUtil.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-01.
//
import AVFoundation
import UIKit

let kErrorDomain = "VEUtil"
let kDateFormatter = DateFormatter()


class VEUtil {
    
    static func getTempFileUrls(count: Int) -> [String] {
        let tmpDir = NSTemporaryDirectory()
        
        var paths: [String] = []
        
        for i in 0..<count {
            let p = tmpDir + "image_\(i).mp4"
            paths.append(p)
        }
        
        for p in paths {
            if FileManager.default.fileExists(atPath: p) {
                try? FileManager.default.removeItem(atPath: p)
            }
        }
        
        return paths
    }
    
    static func createVideoFromImage(image: UIImage, videoSize: CGSize, duration: CMTime, outputURL: URL) async throws -> Error?  {
        // Set up the video writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ] as [String: Any]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Create a pixel buffer pool
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height
        ]
        var pixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, bufferAttributes as CFDictionary, &pixelBufferPool)
        
        // Convert images to video
        guard let pixelBufferPool = pixelBufferPool else {
            return NSError(domain: "PhotoMeidaUtility", code: 1, userInfo: nil)
        }
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        
        guard let buffer = pixelBuffer else {
            return NSError(domain: "PhotoMeidaUtility", code: 2, userInfo: nil)
        }
        
        // Draw image on the pixel buffer
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(videoSize.width), height: Int(videoSize.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        // draw the black background
        context?.setFillColor(UIColor.black.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height))
        
        let imageSize = image.size
        let transform : CGAffineTransform = .identity
        let transformSize = imageSize.applying(transform)
        
        let targetAR = videoSize.width / videoSize.height
        let sourceAR = abs(transformSize.width / transformSize.height)
        
        var scale: CGFloat = 0
        if sourceAR > targetAR {
            scale = videoSize.width / abs(transformSize.width)
        } else {
            scale = videoSize.height / abs(transformSize.height)
        }
        
        let scaleWidth = scale * transformSize.width
        let scaleHeight = scale * transformSize.height
        let dx = (videoSize.width - scaleWidth) / 2.0
        let dy = (videoSize.height - scaleHeight) / 2.0
        
        let drawRect = CGRectMake(dx, dy, scaleWidth, scaleHeight)
        
        context?.draw(image.cgImage!, in: drawRect)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        while !writerInput.isReadyForMoreMediaData {}
        
        adaptor.append(buffer, withPresentationTime: .zero)
        // use duration / 2 so the total time is duration
        let halfDuration = CMTime(seconds: duration.seconds / 2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        adaptor.append(buffer, withPresentationTime: halfDuration)
        
        writerInput.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed {
            return writer.error
        }
        
        return nil
    }
    
    private static func generateInstructions(configures: [(CMTimeRange, [AVAssetTrack], TransitionType)], totalTime: CMTime) -> [AVMutableVideoCompositionInstruction] {
        var ret:[AVMutableVideoCompositionInstruction] = []
        
        // check time range correct or not
        var check: Bool = true
        var curTime: CMTime = .zero
        for (timeRange, tracks, trans) in configures {
            if curTime != timeRange.start {
                check = false
                break
            }
            
            curTime = CMTimeAdd(curTime, timeRange.duration)
        }
        
        guard check else {
            print("layer instruction check failed")
            return ret
        }
        
        // add layer instrction
        for (timeRange, tracks, trans) in configures {
            if tracks.count == 1 {
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = timeRange
                // layer instruction
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[0])
                instruction.layerInstructions = [layerInstruction]
                ret.append(instruction)
                continue
            }
            
            assert(tracks.count == 2)
            guard let instruction = TransitionFactory.createCompositionInstruction(type: trans) else {
                assert(false)
            }
            instruction.timeRange = timeRange
            let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[0])
            let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[1])
            // hacking the code to force to use custom transition
            layerInstruction1.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: timeRange)
            layerInstruction2.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: timeRange)
            instruction.layerInstructions = [layerInstruction1, layerInstruction2]
            ret.append(instruction)
        }
        
        return ret
    }
    
    private static func concatenateVideos(videoURLS: [URL], durations: [CMTime], tranTypes: [TransitionType], transitionDuration: CMTime, videoSize: CGSize, frameDuration: CMTime, customComposeClass: (any AVVideoCompositing.Type), outputURL: URL) async throws -> (AVMutableComposition, AVMutableVideoComposition, CMTime) {
        guard videoURLS.count > 0, durations.count == videoURLS.count, tranTypes.count == videoURLS.count else {
            throw errorWithDes(description: "No videos provided")
        }
        
        let composition = AVMutableComposition()
        
        let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        guard let videoTrack1, let videoTrack2 else {
            throw errorWithDes(description: "can't create video tracks from composition")
        }
        
        var videoAssets = [AVAsset]()
        for url in videoURLS {
            let asset = AVURLAsset(url: url)
            videoAssets.append(asset)
        }
        
        // load video tracks simultaneously
        var loadVideoTracks : [AVAssetTrack?] = Array(repeating: nil, count: videoAssets.count)
        try await withThrowingTaskGroup(of: (Int, AVAssetTrack?).self, body: { group in
            for (index,asset) in videoAssets.enumerated() {
                group.addTask {
                    let asset = try await asset.loadTracks(withMediaType: .video).first
                    return (index, asset)
                }
            }
            for try await (idx, result) in group {
                loadVideoTracks[idx] = result
            }
        })
        
        guard loadVideoTracks.allSatisfy({$0 != nil}) else {
            throw errorWithDes(description: "can't load video tracks")
        }
        
        let videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: composition)
        videoComposition.customVideoCompositorClass = customComposeClass

        var instructionCfgs = [(CMTimeRange, [AVAssetTrack], TransitionType)]()
        
        var curInsertTime = CMTime.zero
        for (idx, videoTrack) in loadVideoTracks.enumerated() {
            let timeRange = CMTimeRange(start: .zero, duration: durations[idx])
            if idx % 2 == 0 {
                try videoTrack1.insertTimeRange(timeRange, of: videoTrack!, at: curInsertTime)
            } else {
                try videoTrack2.insertTimeRange(timeRange, of: videoTrack!, at: curInsertTime)
            }
            
            // all time ranges should be considered
            let hasPreviousTrack = idx > 0
            let hasNextTrack = idx < loadVideoTracks.count - 1
            var transitionType: TransitionType = idx > 0 ? tranTypes[idx-1] : .None
            
            var singleTrackStartTime = curInsertTime
            var singleTrackDuration = timeRange.duration
            if hasPreviousTrack {
                singleTrackStartTime = CMTimeAdd(curInsertTime, transitionDuration)
                // subtract previous transition time
                singleTrackDuration = CMTimeSubtract(timeRange.duration, transitionDuration)
            }
            if hasNextTrack {
                // subtract the next transition time
                singleTrackDuration = CMTimeSubtract(singleTrackDuration, transitionDuration)
            }

            if hasPreviousTrack {
                // add transition instruction
                let transitionTimeRange = CMTimeRange(start: curInsertTime, duration: transitionDuration)
                // front sample, background sample
                let instructionTracks = idx % 2 == 0 ? [videoTrack1, videoTrack2] : [videoTrack2, videoTrack1]
                instructionCfgs.append((transitionTimeRange, instructionTracks, transitionType))
            }
            
            // add single track instruction
            instructionCfgs.append((CMTimeRange(start: singleTrackStartTime, duration: singleTrackDuration), [idx % 2 == 0 ? videoTrack1 : videoTrack2], .None))
            
            curInsertTime = CMTimeAdd(curInsertTime, timeRange.duration)
            if idx < loadVideoTracks.count - 1 {
                // for not last element, subtract transition duration
                curInsertTime = CMTimeSubtract(curInsertTime, transitionDuration)
            }
        }
        
        // curInsertTime is the total duration
        let totalDuration = curInsertTime
        
        videoComposition.instructions = generateInstructions(configures: instructionCfgs, totalTime: curInsertTime)
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = frameDuration
        
        return (composition, videoComposition, totalDuration)
    }
    
    private static func addAudioTrack(to composition: AVMutableComposition, audioURLs: [URL], duration: CMTime) async throws {
        for audioURL in audioURLs {
            let audioAsset = AVURLAsset(url: audioURL)
            let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first
            guard let audioTrack else {
                throw errorWithDes(description: "can't load audio track")
            }

            let audioDuration = try await audioAsset.load(.duration)
            let minDuration = CMTimeMinimum(audioDuration, duration)
                
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: minDuration), of: audioTrack, at: .zero)
        }
    }
    
    static func createVideoForSession(sess: EditSession, outputURL: URL) async -> Error? {
        let images = sess.photos.map {$0.image}
        let durations = sess.photos.map{$0.duration}
        let transTypes = sess.transTypes
        let transDuration = CMTimeMakeWithSeconds(0.5, preferredTimescale: Int32(NSEC_PER_SEC))
        let size = CGSizeMake(CGFloat(sess.videoWidth), CGFloat(sess.videoHeight))

        guard images.count > 0, transTypes.count == images.count else {
            return errorWithDes(description: "No images provided")
        }
        
        let paths = getTempFileUrls(count: images.count)
        
        var errors : [(Int, Error?)] = []
        try? await withThrowingTaskGroup(of: (Int, Error?).self) { group in
            for (index, image) in images.enumerated() {
                let path = paths[index]
                let url = URL(fileURLWithPath: path)
                group.addTask {
                    let error = try? await createVideoFromImage(image: image, videoSize: size, duration: durations[index], outputURL: url)
                    return (index, error)
                }
            }
            for try await result in group {
                errors.append(result)
            }
        }
        
        
        if errors.isEmpty {
            return errorWithDes(description: "create image failed")
        }
        
        if errors.contains(where: {$0.1 != nil}) {
            return errors.first(where:  {$0.1 != nil})?.1
        }
        
        let urls = paths.map{URL(fileURLWithPath: $0)}
        let transitionTime = CMTimeMakeWithSeconds(0.5, preferredTimescale: Int32(NSEC_PER_SEC))
        let frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        do {
            let (comp, videoComp, duration) = try await concatenateVideos(videoURLS: urls, durations: durations, tranTypes: transTypes, transitionDuration: transitionTime, videoSize: size, frameDuration: frameDuration, customComposeClass: ExportCustomVideoCompositor.self, outputURL: outputURL)

            let audioUrls = sess.audios.map{$0.url}
            try await addAudioTrack(to: comp, audioURLs: audioUrls, duration: duration)

            // export
            guard let exportSession = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else {
                return errorWithDes(description: "Export session create failed")
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComp
            
            await exportSession.export()
            switch exportSession.status {
            case .completed:
                return nil
            default:
                return exportSession.error
            }
            
        } catch {
            return error
        }
    }
    
    
    static func errorWithDes(description: String) -> NSError {
        NSError(domain: kErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : description])
    }
    static func createVideoFromImages(images: [UIImage], outputURL: URL) async -> Error?{
        guard !images.isEmpty else {
            return errorWithDes(description: "No images provided")
        }
        
        // Set up the video writer
        let size = images[0].size
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ] as [String: Any]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Create a pixel buffer pool
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: size.width,
            kCVPixelBufferHeightKey as String: size.height
        ]
        var pixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, bufferAttributes as CFDictionary, &pixelBufferPool)
        
        // Convert images to video
        //let frameDuration = CMTime(value: 1, timescale: 1)
        var frameCount: Int64 = 0
        for image in images {
            guard let pixelBufferPool = pixelBufferPool else { continue }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
            
            guard let buffer = pixelBuffer else { continue }
            
            // Draw image on the pixel buffer
            CVPixelBufferLockBaseAddress(buffer, [])
            let pixelData = CVPixelBufferGetBaseAddress(buffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height),
                                    bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            
            while !writerInput.isReadyForMoreMediaData {}
            let time = CMTime(value: frameCount, timescale: 1)
            adaptor.append(buffer, withPresentationTime: time)
            frameCount += 1
        }
        
        writerInput.markAsFinished()
        await writer.finishWriting()
        return writer.error
    }
    
    
    static func addAudioToVideo(videoURL: URL, audioURL: URL, outputURL: URL) async -> Error? {
        let composition = AVMutableComposition()
        
        // Video track
        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)
        
        do {
            let videoDuration = try await videoAsset.load(.duration)
            let videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
            let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)
            
            if let videoTrack = videoTracks.first, let audioTrack = audioTracks.first {
                if let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try videoCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)
                } else {
                    return errorWithDes(description:"Could not add video track")
                }
                
                
                if let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: audioTrack, at: .zero)
                } else {
                    return errorWithDes(description: "Could not add audio track")
                }
                
                // Export the composition
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                    return errorWithDes(description: "AVAssetExportSession init failed")
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mp4
                exportSession.shouldOptimizeForNetworkUse = true
                
                await exportSession.export()
                switch exportSession.status {
                case .completed:
                    return nil
                case .failed:
                    return exportSession.error
                case .cancelled:
                    return nil
                default:
                    return nil
                }
            } else {
                return errorWithDes(description:"videoTracks or audioTrack load failed")
            }
            
        } catch {
            return error
        }
        
    }
    
    
    //MARK: Transition
    //TODO: yy
    static func preview(by transition:TransitionType,
                        canvasSize: CGSize,
                        upImage: UIImage,
                        backImage: UIImage) async -> Result<AVAsset, NSError> {
        
        if canvasSize.equalTo(CGSizeZero) {
            return .success(AVAsset())
        } else {
            return .failure(NSError())
        }
    }
}


extension Date {
    
    func formattedDateString() -> String {
        kDateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        return kDateFormatter.string(from: self)
    }
}
extension UIImage {
    func correctedOrientation() -> UIImage {
        // No need to adjust if the image is already upright
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

