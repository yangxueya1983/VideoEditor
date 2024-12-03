//
//  PhotoPicker.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import PhotosUI

typealias ImageResult = Result<UIImage, Error>

func errorWithDes(_ description: String) -> Error {
    return NSError(domain: "ImagePickerError", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
}


struct PhotoPicker: UIViewControllerRepresentable {
    let pickerDone: (_ selectedImages: [UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // Only allow images to be picked
        configuration.selectionLimit = 0 // 0 means no limit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    //MARK: - Image Loading
    func loadImage(result: PHPickerResult) async -> ImageResult {
        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return .failure(errorWithDes("canLoadObject Error"))
        }
        
        return await withCheckedContinuation { continuation in
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    let correctedImage = image.correctedOrientation()
                    continuation.resume(returning: ImageResult.success(correctedImage))
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .failure(errorWithDes("unknown error")))
                }
            }
        }
    }
    
    func fetchImages(results: [PHPickerResult]) async -> [ImageResult] {
        let defError = NSError(domain: "ImageDownloadError", code: 0, userInfo: nil)
        var imagesResults:[ImageResult] = Array(repeating: .failure(defError), count: results.count)
        
        return await withTaskGroup(of: (Int, ImageResult).self) { group in
            let itemProviders = results.map(\.itemProvider)
            
            for (index, itemProvider) in itemProviders.enumerated() {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.addTask {
                        return await (index, self.loadImage(result: results[index]))
                    }
                }
            }
            
            for await (index, imageResult) in group {
                imagesResults[index] = imageResult
            }
            
            return imagesResults
        }
    }
                                   
    //MARK: Coordinator
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            Task {
                var selectedImages:[UIImage] = []
                let imagesResults = await self.parent.fetchImages(results: results)
                
                for imageResult in imagesResults {
                    switch imageResult {
                    case .success(let image):
                        selectedImages.append(image)
                    case .failure:
                        break
                    }
                }
                
                await MainActor.run {
                    self.parent.pickerDone(selectedImages)
                    picker.dismiss(animated: true)
                }
            }
        }
    }
}


//#Preview {
//    @State var selectedImages: [UIImage] = []
//    PhotoPicker(selectedImages: $selectedImages)
//}
