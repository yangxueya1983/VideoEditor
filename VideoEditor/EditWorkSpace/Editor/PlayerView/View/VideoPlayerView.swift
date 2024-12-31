//
//  VideoPlayerView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var duration: Float64 = 1.0
    @State private var playerObserver: Any?
    @State private var isDragging = false


    var body: some View {
        VStack {
            // Video Player
            VideoPlayer(player: viewModel.player)
                .frame(height: 300)
                .cornerRadius(10)
                .onAppear {
                    setupPlayerObserver()
                    updateDuration()
                }
                .onDisappear {
                    removePlayerObserver()
                    viewModel.pause()
                }
                .background(Color.black)

            // Custom Controls
            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding()

                Slider(value: $currentTime, in: 0...duration, step: 1, onEditingChanged: { editing in
                    if editing {// Start dragging
                        isDragging = true
                        viewModel.player.pause() // Pause during slider drag
                    } else {// End dragging
                        isDragging = false
                        let newTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                        viewModel.player.seek(to: newTime) { _ in
                            viewModel.player.play() // Resume playback
                        }
                    }
                })
                .padding()

                Text(currentTime.formattedTime)
                    .padding(.trailing)
            }
            .padding()
        }
        .task {
//            let asset = AVAsset(url: self.url)
//            duration = asset.duration.seconds
//            print("yxy get duration \(duration)")
            
//            asset.loadMetadata(for: AVMetadataFormat.)
//            asset.load(.duration) { duration, error in
//                if let error = error {
//                    print("Failed to load duration: \(error)")
//                } else if let duration = duration {
//                    let durationInSeconds = CMTimeGetSeconds(duration)
//                    print("Video duration: \(durationInSeconds) seconds")
//                }
//            }
        }
    }

    // Toggle play/pause
    private func togglePlayPause() {
        if isPlaying {
            viewModel.pause()
        } else {
            viewModel.player.seek(to: CMTime.zero)
            viewModel.play()
        }
        isPlaying.toggle()
    }


    // Setup player observer for time changes
    private func setupPlayerObserver() {
        playerObserver = viewModel.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
        }
    }

    // Update duration
    private func updateDuration() {
        if let duration = viewModel.player.currentItem?.duration.seconds, duration > 0 {
            self.duration = duration
        }
    }

    // Remove player observer
    private func removePlayerObserver() {
        if let observer = playerObserver {
            viewModel.player.removeTimeObserver(observer)
            playerObserver = nil
        }
    }
}

extension Double {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//    let url = URL(string: "https://www.apple.com/105/media/us/services/2024/416d7ef9-e5f1-4bdb-9443-3b7a1958236f/anim/hero/large.mp4")!
//        VideoPlayerView()
//    }
//}
