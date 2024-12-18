//
//  VideoPlayerViewModel.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-09-03.
//

import Foundation
import AVKit
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    init() {
        self.player = AVPlayer()
    }

    func updatePlayer(with url: URL) {
        self.player.replaceCurrentItem(with: AVPlayerItem(url: url))
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    func updatePlayer(with asset: AVAsset) {
        self.player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    func play() {
        self.player.play()
    }
    func pause() {
        self.player.pause()
    }
}
