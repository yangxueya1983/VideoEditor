//
//  PhotoPicker.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import PhotosUI

typealias ImageResult = Result<UIImage, Error>

struct PickedPhoto {
    let image: UIImage?
    let error: Error?
    let key: String
}

func errorWithDes(_ description: String) -> Error {
    return NSError(domain: "ImagePickerError", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
}


struct PhotoPicker: UIViewControllerRepresentable {
    let pickerDone: (_ selectedPhotos: [PickedPhoto]) -> Void

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
    
    func fetchImages(results: [PHPickerResult]) async -> [PickedPhoto] {
        let defError = NSError(domain: "ImageDownloadError", code: 0, userInfo: nil)
        var imagesResults:[PickedPhoto] = Array(repeating: PickedPhoto(image: nil, error: defError, key: ""), count: results.count)
        
        return await withTaskGroup(of: (Int, PickedPhoto).self) { group in
            for (index, result) in results.enumerated() {
                    group.addTask {
                        let key = result.assetIdentifier ?? UUID().uuidString + ".jpg"
                        let imgResult = await self.loadImage(result: result)
                        
                        switch imgResult {
                        case .success(let image):
                            if !PicStorage.shared.containsDataForKey(key: key) {
                                _ = try? PicStorage.shared.save(image: image, key: key)
                            }
                            return (index, PickedPhoto(image: image, error: nil, key: key))
                        case .failure(let error):
                            return (index, PickedPhoto(image: nil, error: error, key: key))
                        }
                    }
            }
            
            for await (index, pickedImage) in group {
                imagesResults[index] = pickedImage
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
                let imagesResults = await self.parent.fetchImages(results: results)
                await MainActor.run {
                    self.parent.pickerDone(imagesResults)
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
