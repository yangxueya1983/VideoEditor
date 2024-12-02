//
//  VESelectSrcView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//
import PhotosUI
import UIKit
import SwiftUI

struct VideoEditView: View {
    @State private var isAddMode = false
    @State private var showPicker = false
    @State private var editImages: [UIImage] = []
    @StateObject private var playerVM = VideoPlayerViewModel()
    
    @State var editSession:EditSession
    
    init(editSession: EditSession) {
        self.editSession = editSession
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
    
    var body: some View {
        VStack {
             
            VideoPlayerView(viewModel: playerVM)
            
            Spacer()
            EditorToolView(imageArray: $editImages)
            
            
            
            //TODO: add more complex interaction
            //ClipsEditView(editSession: $editSession)
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { selectedImages in
                editImages.append(contentsOf: selectedImages)
                
                for image in selectedImages {
                    let path = URL.documentsDirectory.appendingPathComponent(Date().formattedDateString() + ".jpg")
                    let photo = PhotoItem(url: path,
                                          image: image,
                                          duration: CMTime(value: 3, timescale: 1))
                    editSession.photos.append(photo)
                }
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
            refreshVideoByTask()
        }
    }

}

//#Preview {
//    VideoEditView()
//}
