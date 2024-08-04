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
    @State private var showPicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var videoPath:URL?

    var body: some View {
        VStack {
            VStack {
                if let url = videoPath {
                    VideoPlayerView(url: url)
                } else {
                    EmptyView().frame(height: 300)
                }
            }
            Spacer()
            if selectedImages.isEmpty {
                Text("No images selected")
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

            Button(action: {
                showPicker = true
            }) {
                Text("Select Photos")
            }
            .sheet(isPresented: $showPicker) {
                PhotoPicker(selectedImages: $selectedImages) { selectedImages in
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formatted() + ".mp4")
                    
                    createVideoFromImages(images: selectedImages, outputURL: outputURL) { error in
                        if let error = error {
                            print("Error creating video: \(error)")
                        } else {
                            print("Video created successfully at \(outputURL)")
                            let fileName = Date().formatted() + "composition.mp4"
                            let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                            if let audioURL = Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3") {
                                print("Video added Audio successfully at \(finalURL)")
                                
                                Task(priority: .high) {
                                    await addAudioToVideo(videoURL: outputURL, audioURL: audioURL, outputURL: finalURL) { success in
                                        if success {
                                            videoPath = finalURL
                                        } else {
                                            print("Export error")
                                        }
                                    }
                                }
                                
                            } else {
                                print("Resource not found.")
                            }
                            
                        }
                    }
                }
            }
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
        }
    }
}

#Preview {
    VideoEditView()
}
