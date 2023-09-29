//
//  Created by Drew Barnes on 27/04/2023.
//

import AVFoundation
import Foundation

extension AMMediaPlayer {

    func setupObservers() {

        player?
            .publisher(for: \.currentItem, options: [.new])
            .sink { [weak self] _ in
                guard let self else { return }
                guard let player = self.player else { return }

                self.status = .itemChanged
                guard player.items().isEmpty && player.currentItem == nil else {
                    return }
                player.removeAllItems()
                player.replaceCurrentItem(with: nil)

                for item in self.playerItems {
                    item.seek(to: .zero, completionHandler: nil)
                    player.insert(item, after: nil)
                }

                self.pause()
            }
            .store(in: &cancellables)

        player?
            .publisher(
                for: \.currentItem?.status,
                options: [.new, .old]
            )
            .sink { [weak self] status in
                guard let self else { return }
                guard let status else { return }

                self.playerCurrentItemStatus = status
                if case .readyToPlay = status {
                    self.status = .ready
                }
            }
            .store(in: &cancellables)

        player?
            .publisher(
                for: \.currentItem?.loadedTimeRanges,
                options: [.new, .old])
            .compactMap { [weak self] loadedTimeRanges -> Double? in
                guard let self else { return nil }
                guard let timeRage = loadedTimeRanges?.first else { return nil }

                return CMTimeGetSeconds(timeRage.timeRangeValue.duration) / self.duration
            }
            .assign(to: \.value, on: bufferTimeValueSubject)
            .store(in: &cancellables)

        player?
            .publisher(for: \.currentItem?.isPlaybackBufferEmpty, options: [.new])
            .sink(receiveValue: { [weak self] _ in
                self?.status = .buffering
            })
            .store(in: &cancellables)

        // listening for event about the status of the playback
        player?.publisher(
            for: \.timeControlStatus, options: [.new, .old]
        ).sink { [weak self] timeControlStatus in
            switch timeControlStatus {
            case .paused:
                self?.status = .paused
            case .playing:
                self?.status = .playing
            case .waitingToPlayAtSpecifiedRate:
                if let status = self?.player?.reasonForWaitingToPlay {
                    switch status {
                    case .noItemToPlay:
                        self?.status = .stopped
                    case .toMinimizeStalls:
                        self?.status = .waitingToPlay
                    case .evaluatingBufferingRate:
                        break
                    default:
                        break
                    }
                }
            default:
                break
            }
        }.store(in: &cancellables)
    }
}

extension AMMediaPlayer {

    func addPeriodicTimeObserver() {
        let interval = CMTime(
            seconds: 0.001,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        timeObserverToken = player?
            .addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main) { [weak self] time in
                guard let self else { return }

                self.updateTimestamps(with: time)
                self.currentTimeSubject.send(CMTimeGetSeconds(time))
            }
    }

    func removePeriodicTimeObserver() {
        guard let timeObserverToken = timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
}

extension AMMediaPlayer {

   func updateTimestamps(with time: CMTime) {
        let currentTime = CMTimeGetSeconds(time)
        let timeElapsed = createTimeString(time: currentTime)
        let timeRemaining = createTimeString(time: (duration - currentTime))

        timeElapsedSubject.send(timeElapsed)
        timeRemaningSubject.send("-\(timeRemaining)")
    }

    private func createTimeString(time: TimeInterval) -> String {
        guard let formattedTime = timeRemainingFormatter.string(from: max(0.0, time)) else {
            return ""
        }

        if time < 10 {
            return "0:0\(formattedTime)"
        } else if time > 10 && time < 60 {
            return "0:\(formattedTime)"
        } else {
            return formattedTime
        }
    }
}
