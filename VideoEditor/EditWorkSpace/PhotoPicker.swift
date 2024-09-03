//
//  PhotoPicker.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import PhotosUI

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

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var selectedImages:[UIImage] = []

            let itemProviders = results.map(\.itemProvider)
            
            let disGroup = DispatchGroup()

            for itemProvider in itemProviders {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    disGroup.enter()
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        
                        guard self != nil else {
                            disGroup.leave()
                            return
                        }
                        if let image = image as? UIImage {
                            let correctedImage = image.correctedOrientation()
                            DispatchQueue.main.async {
                                selectedImages.append(correctedImage)
                                disGroup.leave()
                            }
                        } else {
                            disGroup.leave()
                            print("Error loading image: \(String(describing: error))")
                        }
                    }
                }
            }
            disGroup.notify(queue: .main) {
                self.parent.pickerDone(selectedImages)
            }

            picker.dismiss(animated: true)
        }
    }
}


//#Preview {
//    @State var selectedImages: [UIImage] = []
//    PhotoPicker(selectedImages: $selectedImages)
//}
