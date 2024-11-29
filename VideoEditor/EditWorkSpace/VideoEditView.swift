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
        editImages = editSession.photos.map{$0.image}
    }

    var body: some View {
        VStack {
            VStack {
                VideoPlayerView(viewModel: playerVM)
            }
            Spacer()
            ClipsEditView(editSession: $editSession)

        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { selectedImages in
                editImages.append(contentsOf: selectedImages)
                
                Task {
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formattedDateString() + ".mp4")
                    
                    let error = await VEUtil.createVideoFromImages(images: editImages, outputURL: outputURL)
                    
                    if let error {
                        print("yxy Error creating video: \(error)")
                    } else {
                        print("yxy Video created successfully at \(outputURL)")
                        let fileName = Date().formattedDateString() + "_comp.mp4"
                        let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        if let audioURL = Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3") {
                            print("yxy Video added Audio successfully at \(finalURL)")
                            
                            let error = await VEUtil.addAudioToVideo(videoURL: outputURL, audioURL: audioURL, outputURL: finalURL)
                            if error == nil {
                                print("yxy Video added Audio successfully at \(finalURL)")
                                playerVM.updatePlayer(with: finalURL)
                            } else {
                                print("Export error")
                            }
                        } else {
                            print("Resource not found.")
                        }
                    }
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
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formattedDateString() + ".mp4")
            
            let error = await editSession.exportVideo(outputURL: outputURL)
            if error == nil {
                playerVM.updatePlayer(with: outputURL)
            }
            
        }
    }
}

//#Preview {
//    VideoEditView()
//}
