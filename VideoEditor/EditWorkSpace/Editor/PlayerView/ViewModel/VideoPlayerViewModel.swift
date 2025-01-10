//
//  VideoPlayerViewModel.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-09-03.
//

import Foundation
import AVKit
import SwiftUI

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    @Published var progress: Double = 0.0
    
    private var timeObserver: Any?
    
    var playProgress: Binding<Double> {
        Binding {
            self.progress
        } set: {
            self.progress = $0
        }
    }
    
    init() {
        self.player = AVPlayer()
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: 600) // Observe every second
        // Add time observer to the player
        timeObserver = self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = time.seconds
            if let duration = self.player.currentItem?.duration.seconds, duration > 0 {
                self.progress = currentTime / duration // Calculate progress as a percentage
            } else {
                self.progress = 0.0
            }
        }
    }
    
    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    func updatePlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        updatePlayer(with: item)
    }
    func updatePlayer(with asset: AVAsset) {
        let item = AVPlayerItem(asset: asset)
        updatePlayer(with: item)
    }
    func updatePlayer(with playerItem: AVPlayerItem) {
        self.player.replaceCurrentItem(with: playerItem)
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
