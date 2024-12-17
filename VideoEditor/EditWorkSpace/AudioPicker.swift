//
//  AudioPicker.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-12-16.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreMedia

struct AudioPickerView: UIViewControllerRepresentable {
    let pickerDone: (_ selectedAudios: [AudioItem]) -> Void
    // Binding to send back the selected audio URL to the SwiftUI view
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: AudioPickerView
        
        init(_ parent: AudioPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var audioItems: [AudioItem] = []
            for url in urls {
                let key = PicStorage.shared.cacheKeyForURL(url: url)
                
                if !PicStorage.shared.containsDataForKey(key:key) {
                    if let data = try? Data(contentsOf:url) {
                        _ = try? PicStorage.shared.save(data: data, key: key)
                    }
                }
                let item = AudioItem(cacheKey: key,
                                     selectRange: CMTimeRange(start: .zero, duration: .positiveInfinity),
                                     positionTime: .zero)
                audioItems.append(item)
            }
            parent.pickerDone(audioItems)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.pickerDone([])
        }
    }
}
