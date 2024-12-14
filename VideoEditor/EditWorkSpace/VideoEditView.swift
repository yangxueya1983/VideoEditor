//
//  VESelectSrcView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//
import PhotosUI
import UIKit
import SwiftUI
import SwiftData

struct VideoEditView: View {
    @Environment(\.modelContext) private var modelContext
    private var needPreLoad = false
    @State private var isAddMode = false
    @State private var showPicker = false
    @State private var editImages: [UIImage] = []
    @StateObject private var playerVM = VideoPlayerViewModel()
    
    @State var editSession:EditSession
    
    init(editSession: EditSession, needPreLoad: Bool = false) {
        self.editSession = editSession
        self.needPreLoad = needPreLoad
    }
    
    func refreshVideoByTask() {
        Task {
            //load image
            editImages = editSession.photos.map{$0.image}
            
            
            //make the video
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formattedDateString() + ".mp4")
            let error = await editSession.exportVideo(outputURL: outputURL)
            if error == nil {
                playerVM.updatePlayer(with: outputURL)
            }
        }
    }
    
    
    
    func saveEditSession() {
        modelContext.insert(editSession)
        do {
            try modelContext.save()
            print("save success")
        } catch {
            print("save failed \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        VStack {
             
            VideoPlayerView(viewModel: playerVM)
            
            Spacer()
            EditorToolView(imageArray: $editImages)
            
            
            
            //TODO: add more complex interaction
            //ClipsEditView(editSession: $editSession)
        }
        .onDisappear {
            saveEditSession()
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { selectedPhotos in
                let validPhotos = selectedPhotos.filter { $0.image != nil }
            
                for photo in validPhotos {
                    if let image = photo.image {
                        editImages.append(image)
                        let item = PhotoItem(cacheKey: photo.key,
                                             image: image,
                                             duration: CMTime(value: 3, timescale: 1))
                        editSession.photos.append(item)
                    }
                }
                
                refreshVideoByTask()
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(" Resolution ") {
                    
                }
            })
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(" Export ") {
                    
                }
            })
            
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button("Add image") {
                        showPicker = true
                    }
                    Button("Add music") {
                        
                    }
                    Button("Add text") {
                        
                    }
                    Text("\(editImages.count)")
                }
                
            }
        }
        .task {
            if needPreLoad {
                try? await editSession.preLoadAsserts()
                print("preload done")
            }
            refreshVideoByTask()
        }
    }

}

//#Preview {
//    VideoEditView()
//}
