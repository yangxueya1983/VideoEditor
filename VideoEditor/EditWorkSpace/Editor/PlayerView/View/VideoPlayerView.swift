//
//  VideoPlayerView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @StateObject var viewModel: VideoPlayerViewModel
    
    @State private var isPlaying: Bool = false
    @State private var isDragging = false

    var body: some View {
        VStack {
            // Video Player
            VideoPlayer(player: viewModel.player)
                .frame(height: 300)
                .cornerRadius(10)
                .background(Color.black)

            // Custom Controls
            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding()
                
                Slider(value: $viewModel.progress, in: 0.0...1.0)
                    .padding()

//                Text(currentTime.formattedTime + duration.formattedTime)
//                    .padding(.trailing)
            }
            .padding()
        }
        .task {
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
