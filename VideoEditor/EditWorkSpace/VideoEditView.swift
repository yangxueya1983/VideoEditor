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
    
    @State private var showPhotoPicker = false
    @State private var showAudioPicker = false
    @State private var editImages: [UIImage] = []
    @StateObject private var playerVM = VideoPlayerViewModel()
    @State private var outputVideoURL: URL?
    
    @State var editSession:EditSession
    var transType = TransitionType.None
    
    // Primary initializer
    private init(editSession: EditSession, needPreLoad: Bool = false) {
        self.editSession = editSession
        self.needPreLoad = needPreLoad
        
        if editSession.photos.isEmpty {
            _showPhotoPicker = State(initialValue: true)
        }
    }
    
    init (storageSession:EditSession) {
        self.init(editSession: storageSession, needPreLoad: true)
    }
    
    init(transitionType: TransitionType) {
        self.init(editSession: EditSession())
        transType = transitionType
    }
    
    init() {
        self.init(transitionType: .None)
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
                self.outputVideoURL = outputURL
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
        .sheet(isPresented: $showAudioPicker) {
            AudioPickerView { selectedAudio in
                if !selectedAudio.isEmpty {
                    editSession.audios = selectedAudio
                    refreshVideoByTask()
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { selectedPhotos in
                
                if !selectedPhotos.isEmpty {
            
                    let validPhotos = selectedPhotos.filter { $0.image != nil }
                    
                    for photo in validPhotos {
                        if let image = photo.image {
                            let item = PhotoItem(cacheKey: photo.key,
                                                 image: image,
                                                 duration: CMTime(value: 3, timescale: 1),
                                                 transitionType: transType)
                            editSession.photos.append(item)
                        }
                    }
                    
                    refreshVideoByTask()
                }
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(" Resolution ") {
                    
                }
            })
            if let url = self.outputVideoURL {
                ToolbarItem(placement: .topBarTrailing, content: {
                    ShareLink(item: url, label: { Text("Share") })
                })
            }
            
            
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button("Add image") {
                        showPhotoPicker = true
                    }
                    Button("Add music") {
                        showAudioPicker = true
                    }
                    Text("\(editImages.count) photos")
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
