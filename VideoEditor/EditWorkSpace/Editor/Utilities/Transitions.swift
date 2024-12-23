//
//  Transitions.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-12-21.
//

import AVFoundation
import CoreImage

class CustomVideoCompositionInstructionBase : AVMutableVideoCompositionInstruction {
    func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress : CGFloat, _ size: CGSize) -> CIImage? {
        return nil
    }
}

class NoneTransCompsitionInstruction: CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        return frontSample
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
        let transformImage = backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : frontSample
        ])
        
        return outImage
    }
}

class MoveRightInstruction : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let offset = size.width * process
        let transform = CGAffineTransformMakeTranslation(offset, 0)
        let transformImage = backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : frontSample
        ])
        
        return outImage
    }
}

class MoveUpInstruction: CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let offset = size.height * process
        let transform = CGAffineTransformMakeTranslation(0, offset)
        let transformImage = backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : frontSample
        ])
        
        return outImage
    }
}

class MoveDownInstruction: CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ process: CGFloat, _ size: CGSize) -> CIImage? {
        let offset = -size.height * process
        let transform = CGAffineTransformMakeTranslation(0, offset)
        let transformImage = backgroundSample.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey : transform])
        let outImage = transformImage.applyingFilter("CISourceAtopCompositing", parameters: [
            kCIInputBackgroundImageKey : frontSample
        ])
        
        return outImage
    }
}

class PageCurlInstruction : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress: CGFloat, _ size: CGSize) -> CIImage? {
        let transitionFilter = CIFilter.pageCurlTransition()
        transitionFilter.inputImage = backgroundSample
        transitionFilter.targetImage = frontSample
        transitionFilter.time = Float(progress) // Adjust the time from 0 to 1 to control the transition progress
        transitionFilter.angle = Float(Double.pi) // Control the angle of the curl
        transitionFilter.radius = 100.0 // Control the radius of the curl
        transitionFilter.extent = frontSample.extent // Set the extent of the transition
        return transitionFilter.outputImage
    }
}

class RadiusTransitionFilter: CIFilter {
    private static var kernel: CIKernel? = {
        guard let device = MTLCreateSystemDefaultDevice(),
              let libraryPath = Bundle.main.path(forResource: "default", ofType: "metallib"),
              let libraryData = try? Data(contentsOf: URL(fileURLWithPath: libraryPath)) else {
            return nil
        }
        
        return try? CIKernel(functionName: "radiusTransitionFilter", fromMetalLibraryData: libraryData)
    }()
    
    var inputImage: CIImage?
    var backgroundImage: CIImage?
    var progress: CGFloat = 0.0
    
    override var outputImage: CIImage? {
        guard let inputImage, let backgroundImage else {
            return nil
        }
        
        let size = inputImage.extent.size
        
        let args = [inputImage, backgroundImage, progress] as [Any]
        
        
        return type(of: self).kernel?.apply(extent: inputImage.extent, roiCallback: { idx, rect in
            return rect
        }, arguments: args)
    }
}

class RadiusRotateInstruction : CustomVideoCompositionInstructionBase {
    override func compose(_ frontSample: CIImage, _ backgroundSample: CIImage, _ progress: CGFloat, _ size: CGSize) -> CIImage? {
        let transitionFilter = RadiusTransitionFilter()
        transitionFilter.inputImage = frontSample
        transitionFilter.backgroundImage = backgroundSample
        transitionFilter.progress = progress
        
        return transitionFilter.outputImage
    }
}

enum TransitionType : String, Codable, CaseIterable, Identifiable {
    case None = "None"
    case Dissolve = "Dissolve"
    case CircleEnlarge = "CircleEnlarge"
    case MoveLeft = "MoveLeft"
    case MoveRight = "MoveRight"
    case MoveUp = "MoveUp"
    case MoveDown = "MoveDown"
    case PageCurl = "PageCurl"
    case RadiusRotate = "RadiusRotate"
    
    var id: String { rawValue }
    
    var thumbImgName:String {
        switch self {
        case .None: return "avatar0"
        case .Dissolve: return "avatar1"
        case .CircleEnlarge: return "avatar2"
        case .MoveLeft: return "avatar3"
        case .MoveRight: return "avatar0"
        case .MoveUp: return "avatar1"
        case .MoveDown: return "avatar2"
        case .PageCurl: return "avatar3"
        case .RadiusRotate: return "avatar0"
        }
    }
}

// factory design patterhn
class TransitionFactory {
    static func createCompositionInstruction(type: TransitionType) -> AVMutableVideoCompositionInstruction? {
        switch type {
        case .None:
            return NoneTransCompsitionInstruction()
        case .Dissolve:
            return CrossDissolveCompositionInstruction()
        case .CircleEnlarge:
            return CircleEnlargerCompositionInstruction()
        case .MoveLeft:
            return MoveLeftInstruction()
        case .MoveRight:
            return MoveRightInstruction()
        case .MoveUp:
            return MoveUpInstruction()
        case .MoveDown:
            return MoveDownInstruction()
        case .PageCurl:
            return PageCurlInstruction()
        case .RadiusRotate:
            return RadiusRotateInstruction()
        default :
            return nil
        }
    }
}
