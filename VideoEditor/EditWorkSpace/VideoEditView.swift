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
    
    @State var editSession:EditSession?

    var body: some View {
        VStack {
            VStack {
                VideoPlayerView(viewModel: playerVM)
            }
            Spacer()
            if editImages.count > 0 {
                EditorToolView(imageArray: editImages)
            } else {
                Text("No images selected")
                Button(action: {
                    showPicker = true
                }) {
                    Text("Select Photos")
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { selectedImages in
                
                if let editSession {//add
                    editImages.append(contentsOf: selectedImages)
                } else {//new
                    editImages = selectedImages
                    
                    editSession = EditSession()
                    let array = selectedImages.map { image in
                        PhotoItem(url: Bundle.main.url(forResource: "pic_1", withExtension: "jpg")!,
                                  image: image,
                                  duration: CMTime(value: 3, timescale: 1))
                    }
                    editSession?.photoItems = array
                }
                
                
                Task {
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formattedDateString() + ".mp4")
                    
                    let error = await createVideoFromImages(images: editImages, outputURL: outputURL)
                    
                    if let error {
                        print("yxy Error creating video: \(error)")
                    } else {
                        print("yxy Video created successfully at \(outputURL)")
                        let fileName = Date().formattedDateString() + "_comp.mp4"
                        let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        if let audioURL = Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3") {
                            print("yxy Video added Audio successfully at \(finalURL)")
                            
                            let error = await addAudioToVideo(videoURL: outputURL, audioURL: audioURL, outputURL: finalURL)
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
                }
                
            }
        }
        .task {
            let imageSrcURLArray =  [Bundle.main.url(forResource: "pic_1", withExtension: "jpg")!,
                                     Bundle.main.url(forResource: "pic_2", withExtension: "jpg")!,
                                     Bundle.main.url(forResource: "pic_3", withExtension: "jpg")!,
                                     Bundle.main.url(forResource: "pic_4", withExtension: "jpg")!]
            
            editSession = EditSession()
            let array = imageSrcURLArray.map { path in
                PhotoItem(url: path,
                          image: UIImage(contentsOfFile: path.path())!,
                          duration: CMTime(value: 3, timescale: 1))
            }
            editSession?.photoItems = array
            
            let imgArray = imageSrcURLArray.map { path in
                UIImage(contentsOfFile: path.path())!
            }
            editImages = imgArray
            
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formatted() + ".mp4")
            
            let error = await createVideoFromImages(images: editImages, outputURL: outputURL)
            
            if let error {
                print("Error creating video: \(error)")
            } else {
                print("Video created successfully at \(outputURL)")
                let fileName = Date().formatted() + "composition.mp4"
                let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                if let audioURL = Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3") {
                    print("Video added Audio successfully at \(finalURL)")
                    
                    let error = await addAudioToVideo(videoURL: outputURL, audioURL: audioURL, outputURL: finalURL)
                    if error == nil {
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
}

#Preview {
    VideoEditView()
}
