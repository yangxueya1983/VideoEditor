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
    
    static func createVideoFromImages(images: [UIImage], outputURL: URL) async -> Error?{
        guard !images.isEmpty else {
            return NSError(domain: kErrorDomain,
                           code: 0,
                           userInfo: [NSLocalizedDescriptionKey: "No images provided"])
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
        let videoDuration = videoAsset.duration
        
        do {
            let videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
            let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)
            
            if let videoTrack = videoTracks.first, let audioTrack = audioTracks.first {
                let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)
                
                let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: audioTrack, at: .zero)
                
                // Export the composition
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                    return NSError(domain: kErrorDomain,
                                   code: 0,
                                   userInfo: [NSLocalizedDescriptionKey: "AVAssetExportSession init failed"])
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
                return NSError(domain: kErrorDomain,
                               code: 0,
                               userInfo: [NSLocalizedDescriptionKey: "videoTracks or audioTrack load failed"])
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

