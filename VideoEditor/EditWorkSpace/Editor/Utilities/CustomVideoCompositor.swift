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
import UIKit

class CustomVideoCompositionInstructionBase : AVMutableVideoCompositionInstruction {
    func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process : CGFloat, _ size: CGSize) -> CIImage? {
        return nil
    }
}

class CrossDissolveCompositionInstruction : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let blendedImage = frontSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: backgroundSample,
            kCIInputMaskImageKey: CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: process)).cropped(to: frontSample.extent)
        ])
        
        return blendedImage
    }
}

class CircleEnlargerCompositionInstruction : CustomVideoCompositionInstructionBase {
    func createCenterRadiusMask(size: CGSize, progress: CGFloat) -> CIImage? {
        let center = CIVector(x: size.width / 2, y: size.height / 2)
        let radius = sqrt(size.width * size.width +  size.height * size.height) / 2  * progress
        
        // Create a radial gradient filter for the transition effect
        let gradientFilter = CIFilter(name: "CIRadialGradient")!
        gradientFilter.setValue(center, forKey: "inputCenter")
        gradientFilter.setValue(radius, forKey: "inputRadius0") // Inner radius (start of gradient)
        gradientFilter.setValue(radius + 1, forKey: "inputRadius1") // Outer radius (end of gradient)
        gradientFilter.setValue(CIColor.white, forKey: "inputColor0") // Inside color (visible area)
        gradientFilter.setValue(CIColor.black, forKey: "inputColor1") // Outside color (masked area)
        
        // Crop the gradient to the image size
        return gradientFilter.outputImage?.cropped(to: CGRect(origin: .zero, size: size))
    }
    
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let maskImage = self.createCenterRadiusMask(size: size, progress: process)
        let blendFilter = CIFilter(name: "CIBlendWithMask")
        blendFilter?.setValue(frontSample, forKey: kCIInputImageKey)
        blendFilter?.setValue(backgroundSample, forKey: kCIInputBackgroundImageKey)
        blendFilter?.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter?.outputImage
    }
}

class MoveLeftInstruction : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let offset = -size.width * process
        let transform = CGAffineTransformMakeTranslation(offset, 0)
        let transformImage = frontSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : backgroundSample
        ])
        
        return outImage
    }
}

class DissolveMoveInstruction : CustomVideoCompositionInstructionBase {
    var mask : CIImage?
    func getDirX() -> CGFloat { return 0 }
    func getDirY() -> CGFloat { return 0 }
    
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        // mask must be already set
        if mask == nil {
            // create the mask
            mask = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: frontSample.extent)
        }
        
        let offsetX = size.width  * getDirX() * process
        let offsetY = size.height * getDirY() * process
        let transform = CGAffineTransformMakeTranslation(offsetX, offsetY)
        let offsetMask = mask!.applyingFilter("CIAffineTransform", parameters: [
            kCIInputTransformKey: transform
        ])
        
        let blendedImage = frontSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: backgroundSample,
            kCIInputMaskImageKey: offsetMask
        ])
        return blendedImage
    }
}

class DissolveMoveLeftInstruction : DissolveMoveInstruction {
    override func getDirX() -> CGFloat { return -1 }
}

class DissolveMoveRightInstruction : DissolveMoveInstruction {
    override func getDirX() -> CGFloat { return 1 }
}

class DissolveMoveUpInstruction : DissolveMoveInstruction {
    // TODO: what is the coordinates? if up y positive?
    override func getDirY() -> CGFloat { return 1 }
}

class DissolveMoveDownInstruction : DissolveMoveInstruction {
    // TODO: still not right at the end of transition
    override func getDirY() -> CGFloat { return -1 }
}

class RadiusDissolveInstruction : CustomVideoCompositionInstructionBase {
    
    private func createMaskImage(size: CGSize, process: CGFloat) -> CIImage {
        let radius = sqrt(size.width * size.width + size.height * size.height) / 2
         
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0 // need to set 1 as the CIImage use pixel level
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let center = CGPointMake(size.width/2, size.height/2)
            ctx.move(to: center)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * Double.pi * process, clockwise: false)
            ctx.closePath()
            ctx.fillPath()
        }
        
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -size.height)
        return CIImage(cgImage: image.cgImage!).transformed(by: transform)
    }
    
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let maskImage = createMaskImage(size: size, process: process)
        
        let blendedImage = backgroundSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: frontSample,
            kCIInputMaskImageKey: maskImage
        ])
        
        return blendedImage
    }
}

/**
 相片切换 in 剪映
 */
class PhotoTransitionInstruction1 : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let angle = Double.pi / 4 * process
        let translateX = -size.width * process
        let translateY = size.height / 2 * process
        
        // front image translation
        let transform = CGAffineTransformMakeRotation(angle).translatedBy(x: translateX, y: translateY)
        let transformImage = frontSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        
        // back image translation
        let scale = 0.8 + 0.2 * process
        let translateBack = CGAffineTransform(translationX: size.width/2, y: size.height/2)
        let transform2 = translateBack.scaledBy(x: scale, y: scale).translatedBy(x: -size.width/2, y: -size.height/2)
        
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform2])
        ])
        return outImage
    }
}

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
            
            let videoSize = renderContext.size
            
            // Retrieve source frames
            guard let foregroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
                  let backgroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[1].int32Value) else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 1, userInfo: nil))
                return
            }
            
            // Apply transition effect (crossfade example)
            let transitionFactor =  CGFloat(CMTimeGetSeconds(asyncVideoCompositionRequest.compositionTime) / CMTimeGetSeconds(asyncVideoCompositionRequest.videoCompositionInstruction.timeRange.duration))
            let outputPixelBuffer = renderContext.newPixelBuffer()
            
            // Create CIImages from the pixel buffers
            let ciForeground = CIImage(cvPixelBuffer: foregroundFrame)
            let ciBackground = CIImage(cvPixelBuffer: backgroundFrame)
            
            guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? CustomVideoCompositionInstructionBase else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "instruction is not CustomVideoCompositionInstructionBase", code: 0))
                return
            }
            
            let blendedImage = instruction.compose(ciForeground, ciBackground, transitionFactor, videoSize)
            
            // Render the blended image into the output buffer
            let ciContext = CIContext()
            ciContext.render(blendedImage!, to: outputPixelBuffer!)
            
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



