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
import CoreImage.CIFilterBuiltins
import OSLog

//class CrossDissolveCompositionInstruction : CustomVideoCompositionInstructionBase {
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        let blendedImage = frontSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
//            kCIInputBackgroundImageKey: backgroundSample,
//            kCIInputMaskImageKey: CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: process)).cropped(to: frontSample.extent)
//        ])
//        
//        return blendedImage
//    }
//}
//
//class CircleEnlargerCompositionInstruction : CustomVideoCompositionInstructionBase {
//    func createCenterRadiusMask(size: CGSize, progress: CGFloat) -> CIImage? {
//        let center = CIVector(x: size.width / 2, y: size.height / 2)
//        let radius = sqrt(size.width * size.width +  size.height * size.height) / 2  * progress
//        
//        // Create a radial gradient filter for the transition effect
//        let gradientFilter = CIFilter(name: "CIRadialGradient")!
//        gradientFilter.setValue(center, forKey: "inputCenter")
//        gradientFilter.setValue(radius, forKey: "inputRadius0") // Inner radius (start of gradient)
//        gradientFilter.setValue(radius + 1, forKey: "inputRadius1") // Outer radius (end of gradient)
//        gradientFilter.setValue(CIColor.white, forKey: "inputColor0") // Inside color (visible area)
//        gradientFilter.setValue(CIColor.black, forKey: "inputColor1") // Outside color (masked area)
//        
//        // Crop the gradient to the image size
//        return gradientFilter.outputImage?.cropped(to: CGRect(origin: .zero, size: size))
//    }
//    
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        let maskImage = self.createCenterRadiusMask(size: size, progress: process)
//        let blendFilter = CIFilter(name: "CIBlendWithMask")
//        blendFilter?.setValue(frontSample, forKey: kCIInputImageKey)
//        blendFilter?.setValue(backgroundSample, forKey: kCIInputBackgroundImageKey)
//        blendFilter?.setValue(maskImage, forKey: kCIInputMaskImageKey)
//        
//        return blendFilter?.outputImage
//    }
//}
//
//class MoveLeftInstruction : CustomVideoCompositionInstructionBase {
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        let offset = -size.width * process
//        let transform = CGAffineTransformMakeTranslation(offset, 0)
//        let transformImage = frontSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
//        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
//            kCIInputBackgroundImageKey : backgroundSample
//        ])
//        
//        return outImage
//    }
//}
//
//class DissolveMoveInstruction : CustomVideoCompositionInstructionBase {
//    var mask : CIImage?
//    func getDirX() -> CGFloat { return 0 }
//    func getDirY() -> CGFloat { return 0 }
//    
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        // mask must be already set
//        if mask == nil {
//            // create the mask
//            mask = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: frontSample.extent)
//        }
//        
//        let offsetX = size.width  * getDirX() * process
//        let offsetY = size.height * getDirY() * process
//        let transform = CGAffineTransformMakeTranslation(offsetX, offsetY)
//        let offsetMask = mask!.applyingFilter("CIAffineTransform", parameters: [
//            kCIInputTransformKey: transform
//        ])
//        
//        let blendedImage = frontSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
//            kCIInputBackgroundImageKey: backgroundSample,
//            kCIInputMaskImageKey: offsetMask
//        ])
//        return blendedImage
//    }
//}
//
//class DissolveMoveLeftInstruction : DissolveMoveInstruction {
//    override func getDirX() -> CGFloat { return -1 }
//}
//
//class DissolveMoveRightInstruction : DissolveMoveInstruction {
//    override func getDirX() -> CGFloat { return 1 }
//}
//
//class DissolveMoveUpInstruction : DissolveMoveInstruction {
//    // TODO: what is the coordinates? if up y positive?
//    override func getDirY() -> CGFloat { return 1 }
//}
//
//class DissolveMoveDownInstruction : DissolveMoveInstruction {
//    // TODO: still not right at the end of transition
//    override func getDirY() -> CGFloat { return -1 }
//}
//
//class RadiusDissolveInstruction : CustomVideoCompositionInstructionBase {
//    
//    private func createMaskImage(size: CGSize, process: CGFloat) -> CIImage {
//        let radius = sqrt(size.width * size.width + size.height * size.height) / 2
//         
//        let format = UIGraphicsImageRendererFormat.default()
//        format.scale = 1.0 // need to set 1 as the CIImage use pixel level
//        
//        let renderer = UIGraphicsImageRenderer(size: size, format: format)
//        let image = renderer.image { context in
//            let ctx = context.cgContext
//            let center = CGPointMake(size.width/2, size.height/2)
//            ctx.move(to: center)
//            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * Double.pi * process, clockwise: false)
//            ctx.closePath()
//            ctx.fillPath()
//        }
//        
//        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -size.height)
//        return CIImage(cgImage: image.cgImage!).transformed(by: transform)
//    }
//    
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        let maskImage = createMaskImage(size: size, process: process)
//        
//        let blendedImage = backgroundSample.applyingFilter("CIBlendWithAlphaMask", parameters: [
//            kCIInputBackgroundImageKey: frontSample,
//            kCIInputMaskImageKey: maskImage
//        ])
//        
//        return blendedImage
//    }
//}
//
///**
// 相片切换 in 剪映
// */
//class PhotoTransitionInstruction1 : CustomVideoCompositionInstructionBase {
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
//        let angle = Double.pi / 4 * process
//        let translateX = -size.width * process
//        let translateY = size.height / 2 * process
//        
//        // front image translation
//        let transform = CGAffineTransformMakeRotation(angle).translatedBy(x: translateX, y: translateY)
//        let transformImage = frontSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
//        
//        // back image translation
//        let scale = 0.8 + 0.2 * process
//        let translateBack = CGAffineTransform(translationX: size.width/2, y: size.height/2)
//        let transform2 = translateBack.scaledBy(x: scale, y: scale).translatedBy(x: -size.width/2, y: -size.height/2)
//        
//        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
//            kCIInputBackgroundImageKey : backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform2])
//        ])
//        return outImage
//    }
//}
//
//class EnlargeTransitionInstruction : CustomVideoCompositionInstructionBase {
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress: CGFloat, _ size: CGSize) -> CIImage? {
//        let changeThreshold = 0.2
//        let frontChangeToScale = 1.2
//        let translateBack = CGAffineTransform(translationX: size.width/2, y: size.height/2)
//        if progress < changeThreshold {
//            // 1 -> 1.2 in changeThreshold progess
//            let frontScale = 1 + (frontChangeToScale - 1) * progress / changeThreshold
//            
//            let transform = translateBack.scaledBy(x: frontScale, y: frontScale).translatedBy(x: -size.width/2, y: -size.height/2)
//            return frontSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
//        }
//        
//        // TODO: add a custom filter to cover the whole background
//        let backInitialScale = 0.7
//        let backScale = backInitialScale + ( 1 - backInitialScale) * (progress - changeThreshold) / ( 1 - changeThreshold)
//        let transform = translateBack.scaledBy(x: backScale, y: backScale).translatedBy(x: -size.width/2, y: -size.height/2)
//        
//        return backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
//    }
//}
//
//class PageCurlTransitionInstruction : CustomVideoCompositionInstructionBase {
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress: CGFloat, _ size: CGSize) -> CIImage? {
//        let transitionFilter = CIFilter.pageCurlTransition()
//        transitionFilter.inputImage = frontSample
//        transitionFilter.targetImage = backgroundSample
//        transitionFilter.time = Float(progress) // Adjust the time from 0 to 1 to control the transition progress
//        transitionFilter.angle = Float(Double.pi) // Control the angle of the curl
//        transitionFilter.radius = 100.0 // Control the radius of the curl
//        transitionFilter.extent = frontSample.extent // Set the extent of the transition
//        return transitionFilter.outputImage
//    }
//}
//
//
//// below method is not correct, need to use 3d model to determine the z position
//// will try to use mental + core image
//class Cube3DTransitionInstruction : CustomVideoCompositionInstructionBase {
//    private var projectionMatrix : simd_float4x4?
//    
//    private func computeCoordinate(origPos: simd_float3, rotationCenter: simd_float3, rotationAxis: simd_float3, rotationAngle: Float, width: CGFloat, height: CGFloat) -> CGPoint {
//        let quaternion = simd_quaternion(rotationAngle, rotationAxis)
//        let translatePos = origPos - rotationCenter
//        let rotationVec = simd_act(quaternion, translatePos)
//        let finalPos = rotationVec + rotationCenter // map to original
//        let homogenVec = simd_float4(finalPos, 1.0)
//        
//        let projectVec = projectionMatrix! * homogenVec
//        let ndcVec = projectVec / projectVec.w
//        
//        let screenX = (ndcVec.x + 1) / 2 * Float(width)
//        // CIImage coordinate
//        let screenY = (ndcVec.y + 1) / 2 * Float(height)
//        return CGPointMake(CGFloat(screenX), CGFloat(screenY))
//    }
//    
//    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress: CGFloat, _ size: CGSize) -> CIImage? {
//        let aspectRatio: Float = Float(size.width) / Float(size.height)
//        let fov : Float = .pi / 2
//        let nearPlane : Float = 0.1
//        let farPlane : Float  = 100
//        
//        if projectionMatrix == nil {
//            projectionMatrix = simd_float4x4(
//                simd_float4(1 / (aspectRatio * tan(fov / 2)), 0, 0, 0),
//                simd_float4(0, 1 / tan(fov / 2), 0, 0),
//                simd_float4(0, 0, -(farPlane + nearPlane) / (farPlane - nearPlane), -1),
//                simd_float4(0, 0, -2 * farPlane * nearPlane / (farPlane - nearPlane), 0)
//            )
//        }
//        
//        let frontLeftTop = simd_float3(-aspectRatio, 1, -1)
//        let frontLeftBot = simd_float3(-aspectRatio, -1, -1)
//        let frontRightTop = simd_float3(aspectRatio, 1, -1)
//        let frontRightBot = simd_float3(aspectRatio, -1, -1)
//        
//        let rotationCenter = simd_float3(0, 0, -1 - aspectRatio)
//        let rotationAxis = simd_float3(0, 1, 0)
//        
//        // right hand rule
//        let angle = Float.pi/2 * Float(progress)
//        let frontMapLT = computeCoordinate(origPos: frontLeftTop, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let frontMapLB = computeCoordinate(origPos: frontLeftBot, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let frontMapRT = computeCoordinate(origPos: frontRightTop, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let frontMapRB = computeCoordinate(origPos: frontRightBot, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        
//        let perspectiveFilter1 = CIFilter(name: "CIPerspectiveTransform")
//        perspectiveFilter1?.setValue(frontSample, forKey: kCIInputImageKey)
//        
//        perspectiveFilter1?.setValue(CIVector(cgPoint: frontMapLT), forKey: "inputTopLeft")
//        perspectiveFilter1?.setValue(CIVector(cgPoint: frontMapRT), forKey: "inputTopRight")
//        perspectiveFilter1?.setValue(CIVector(cgPoint: frontMapLB), forKey: "inputBottomLeft")
//        perspectiveFilter1?.setValue(CIVector(cgPoint: frontMapRB), forKey: "inputBottomRight")
//        
//        
//        // to display image
//        let backLeftTop = simd_float3(-aspectRatio, 1, -1 - 2 * aspectRatio)
//        let backLeftBot = simd_float3(-aspectRatio, -1, -1 - 2 * aspectRatio)
//        let backRightTop = frontLeftTop
//        let backRightBot = frontLeftBot
//        
//        let backMapLT = computeCoordinate(origPos: backLeftTop, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let backMapLB = computeCoordinate(origPos: backLeftBot, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let backMapRT = computeCoordinate(origPos: backRightTop, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let backMapRB = computeCoordinate(origPos: backRightBot, rotationCenter: rotationCenter, rotationAxis: rotationAxis, rotationAngle: angle, width: size.width, height: size.height)
//        let perspectiveFilter2 = CIFilter(name: "CIPerspectiveTransform")
//        perspectiveFilter2?.setValue(backgroundSample, forKey: kCIInputImageKey)
//        
//        perspectiveFilter2?.setValue(CIVector(cgPoint: backMapLT), forKey: "inputTopLeft")
//        perspectiveFilter2?.setValue(CIVector(cgPoint: backMapRT), forKey: "inputTopRight")
//        perspectiveFilter2?.setValue(CIVector(cgPoint: backMapLB), forKey: "inputBottomLeft")
//        perspectiveFilter2?.setValue(CIVector(cgPoint: backMapRB), forKey: "inputBottomRight")
//        
//        return perspectiveFilter2?.outputImage
//        
////        return perspectiveFilter2?.outputImage?.applyingFilter("CISourceAtopCompositing", parameters: [
////            kCIInputBackgroundImageKey : perspectiveFilter1?.outputImage])
//    }
//}

//class CustomVideoCompositor: NSObject, AVVideoCompositing {
//    private let renderContextQueue = DispatchQueue(label: "com.example.CustomVideoCompositor.renderContextQueue")
//    private let renderingQueue = DispatchQueue(label: "com.example.CustomVideoCompositor.renderingQueue")
//    private var renderContext: AVVideoCompositionRenderContext?
//    
//    // Specify the required pixel buffer attributes
//    var sourcePixelBufferAttributes: [String : Any]? {
//        return [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//    }
//    
//    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
//        return [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//    }
//    
//    // Render context is updated when the composition starts
//    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
//        renderContextQueue.sync {
//            renderContext = newRenderContext
//        }
//    }
//    
//    // Main rendering method
//    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
//        renderingQueue.async {
//            guard let renderContext = self.renderContext else {
//                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 0, userInfo: nil))
//                return
//            }
//            
//            let videoSize = renderContext.size
//            
//            // Retrieve source frames
//            guard let foregroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
//                  let backgroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[1].int32Value) else {
//                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 1, userInfo: nil))
//                return
//            }
//            
//            // Apply transition effect (crossfade example)
//            let transitionFactor =  CGFloat(CMTimeGetSeconds(asyncVideoCompositionRequest.compositionTime) / CMTimeGetSeconds(asyncVideoCompositionRequest.videoCompositionInstruction.timeRange.duration))
//            let outputPixelBuffer = renderContext.newPixelBuffer()
//            
//            // Create CIImages from the pixel buffers
//            let ciForeground = CIImage(cvPixelBuffer: foregroundFrame)
//            let ciBackground = CIImage(cvPixelBuffer: backgroundFrame)
//            
//            guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? CustomVideoCompositionInstructionBase else {
//                asyncVideoCompositionRequest.finish(with: NSError(domain: "instruction is not CustomVideoCompositionInstructionBase", code: 0))
//                return
//            }
//            
//            let blendedImage = instruction.compose(ciForeground, ciBackground, transitionFactor, videoSize)
//            
//            // Render the blended image into the output buffer
//            let ciContext = CIContext()
//            ciContext.render(blendedImage!, to: outputPixelBuffer!)
//            
//            // Finish the request with the output pixel buffer
//            asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputPixelBuffer!)
//        }
//    }
//    
//    func cancelAllPendingVideoCompositionRequests() {
//        renderingQueue.sync {
//            // Cancel any pending requests
//        }
//    }
//}


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
    
    func getLayerInstruction(request: AVAsynchronousVideoCompositionRequest) -> CustomVideoCompositionInstructionBase? {
        assert(false, "getLayerInstruction is not implemented")
        return nil
    }
    
    // Main rendering method
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            guard let renderContext = self.renderContext else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 0, userInfo: nil))
                return
            }
            
            let videoSize = renderContext.size
            
            if asyncVideoCompositionRequest.sourceTrackIDs.count == 1 {
                // pass through for only 1 track
                guard let frame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value) else {
                    Logger.viewCycle.debug("compositor single track frame is nil")
                    return
                }
                
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: frame)
                return
            }
            
            // Retrieve source frames
            guard let foregroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
                  let backgroundFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[1].int32Value) else {
                asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: 1, userInfo: nil))
                return
            }
            
            // Apply transition effect (crossfade example)
            let instrTimeRange = asyncVideoCompositionRequest.videoCompositionInstruction.timeRange
            assert(CMTimeCompare(instrTimeRange.start, asyncVideoCompositionRequest.compositionTime) <= 0)
            let transitionFactor =  CGFloat(CMTimeGetSeconds(CMTimeSubtract(asyncVideoCompositionRequest.compositionTime, instrTimeRange.start)))  / CMTimeGetSeconds(asyncVideoCompositionRequest.videoCompositionInstruction.timeRange.duration)
            let outputPixelBuffer = renderContext.newPixelBuffer()
            
            // Create CIImages from the pixel buffers
            let ciForeground = CIImage(cvPixelBuffer: foregroundFrame)
            let ciBackground = CIImage(cvPixelBuffer: backgroundFrame)
            
            guard let instruction = self.getLayerInstruction(request: asyncVideoCompositionRequest) else {
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

class ExportCustomVideoCompositor :  CustomVideoCompositor {
    override func getLayerInstruction(request: AVAsynchronousVideoCompositionRequest) -> CustomVideoCompositionInstructionBase? {
        if let instruction = request.videoCompositionInstruction as? CustomVideoCompositionInstructionBase {
            return instruction
        }
        return nil
    }
}
