//
//  CustomVideoCompositor.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-18.
//

import Foundation
import AVFoundation
import CoreVideo
import CoreImage


class CustomVideoCompositor: NSObject, AVVideoCompositing {
    private let renderContextQueue = DispatchQueue(label: "com.example.CustomVideoCompositor.renderContextQueue")
    private let renderingQueue = DispatchQueue(label: "com.example.CustomVideoCompositor.renderingQueue")
    private var renderContext: AVVideoCompositionRenderContext?
    
    // Specify the required pixel buffer attributes
    var sourcePixelBufferAttributes: [String : Any]? {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
    }
    
    // Render context is updated when the composition starts
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            renderContext = newRenderContext
        }
    }
    
    // Main rendering method
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            guard let renderContext = self.renderContext else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 0, userInfo: nil))
                return
            }
            
            // Retrieve source frames
            guard let foregroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
                  let backgroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[1].int32Value) else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 1, userInfo: nil))
                return
            }
            
            // Apply transition effect (crossfade example)
            let transitionFactor =  CGFloat(CMTimeGetSeconds(asyncVideoCompositionRequest.compositionTime) / CMTimeGetSeconds(asyncVideoCompositionRequest.videoCompositionInstruction.timeRange.duration))
            print("transition factor is \(transitionFactor)")
            let outputPixelBuffer = renderContext.newPixelBuffer()
            
            // Create CIImages from the pixel buffers
            let ciForeground = CIImage(cvPixelBuffer: foregroundFrame)
            let ciBackground = CIImage(cvPixelBuffer: backgroundFrame)
            
            // Blend the images using a crossfade
            let blendedImage = ciForeground.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: ciBackground,
                kCIInputMaskImageKey: CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: transitionFactor)).cropped(to: ciForeground.extent)
            ])
            
            // Render the blended image into the output buffer
            let ciContext = CIContext()
            ciContext.render(blendedImage, to: outputPixelBuffer!)
            
            // Finish the request with the output pixel buffer
            asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputPixelBuffer!)
        }
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        renderingQueue.sync {
            // Cancel any pending requests
        }
    }
}



