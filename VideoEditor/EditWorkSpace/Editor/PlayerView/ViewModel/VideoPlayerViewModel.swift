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
    
    private var playerObserver: Any?
    
    var playProgress: Binding<Double> {
        Binding {
            self.progress
        } set: {
            self.progress = $0
        }
    }
    
    init() {
        self.player = AVPlayer()
    }
    
    deinit {
        if let playerObserver {
            player.removeTimeObserver(playerObserver)
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
        playerObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: nil) { time in

            //guard let self else { return }
            guard let item = self.player.currentItem else { return }
            guard item.duration.seconds.isNormal else { return }
            
            self.progress = time.seconds / item.duration.seconds
        }
        
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
