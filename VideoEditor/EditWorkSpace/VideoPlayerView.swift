//
//  VideoPlayerView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url:URL
    @State private var player: AVPlayer
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var duration: Float64 = 0.0
    @State private var playerObserver: Any?
    
    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }


    var body: some View {
        VStack {
            // Video Player
            VideoPlayer(player: player)
                .frame(height: 300)
                .cornerRadius(10)
                .onAppear {
                    setupPlayerObserver()
                    updateDuration()
                }
                .onDisappear {
                    player.pause()
                    removePlayerObserver()
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

                Slider(value: $currentTime, in: 0...duration, onEditingChanged: sliderEditingChanged)
                    .padding()

                Text(currentTime.formattedTime)
                    .padding(.trailing)
            }
            .padding()
        }
        .task {
            let asset = AVAsset(url: self.url)
            duration = asset.duration.seconds
            print("yxy get duration \(duration)")
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
            player.pause()
        } else {
            player.seek(to: CMTime.zero)
            player.play()
        }
        isPlaying.toggle()
    }

    // Slider editing changed
    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            player.pause()
        } else {
            let newTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player.seek(to: newTime) { _ in
                if isPlaying {
                    player.play()
                }
            }
        }
    }

    // Setup player observer for time changes
    private func setupPlayerObserver() {
        playerObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
        }
    }

    // Update duration
    private func updateDuration() {
        if let duration = player.currentItem?.duration.seconds, duration > 0 {
            self.duration = duration
        }
    }

    // Remove player observer
    private func removePlayerObserver() {
        if let observer = playerObserver {
            player.removeTimeObserver(observer)
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

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(url: URL(string: "https://www.apple.com/105/media/us/services/2024/416d7ef9-e5f1-4bdb-9443-3b7a1958236f/anim/hero/large.mp4")!)
    }
}
