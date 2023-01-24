//
//  Player.swift
//  Parakeet
//
//  Created by Chris Brind on 10/01/2023.
//

import Foundation
import AVFoundation

class Player {

    let audioProgress: (String, Double) -> Void
    let audioFinished: (String) -> Void

    var current: String?
    var player: AVPlayer?
    var timeObserverToken: Any?
    var statusObserver: Any?

    init(audioProgress: @escaping (String, Double) -> Void,
         audioFinished: @escaping (String) -> Void) {
        self.audioProgress = audioProgress
        self.audioFinished = audioFinished
    }

    func play(file: String, inFolder folder: String) {
        stop()
        current = file

        let url = URL(fileURLWithPath: folder).appending(path: file)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        addPeriodicTimeObserver()
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.2,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken =
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                [weak self] time in

                guard let current = self?.current,
                      let duration = self?.player?.currentItem?.duration.seconds else { return }

                let position = time.seconds / duration
                if position >= 1.0 {
                    self?.stop()
                } else {
                    self?.audioProgress(current, position)
                }
        }
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        if let current = current {
            self.current = nil
            audioFinished(current)
        }
        player = nil
    }

    func setPosition(_ position: Double) {
        guard current != nil,
              let duration = player?.currentItem?.duration.seconds else { return }

        let targetPosition = duration * position
        print(#function, targetPosition, duration, position)

        Task {
            await player?.seek(to: .init(seconds: targetPosition, preferredTimescale: 1))
            player?.play()
        }
    }

}

extension AVPlayerItem.Status {

    var description: String {
        switch self {
        case .failed: return "failed"
        case .readyToPlay: return "readyToPlay"
        case .unknown: return "unknown"
        default: return "default:\(self.rawValue)"
        }
    }

}
