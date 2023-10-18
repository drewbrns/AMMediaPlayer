//
//  Created by Drew Barnes on 13/03/2020.
//

import AVFoundation
import Combine

@MainActor
public final class AMMediaPlayer: Player {

    public static var shared = AMMediaPlayer()

    public enum PlaybackStatus {
        case unknown
        case ready
        case buffering
        case waitingToPlay
        case playing
        case paused
        case itemChanged(AVPlayerItem?)
        case stopped
    }

    public var nowPlaying: AVPlayerItem? {
        return player?.currentItem
    }

    var cancellables: Set<AnyCancellable> = []

    public let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    public let durationSubject = CurrentValueSubject<Double, Never>(0)
    public let timeElapsedSubject = CurrentValueSubject<String?, Never>("--:--")
    public let timeRemaningSubject = CurrentValueSubject<String?, Never>("--:--")
    public let currentTimeSubject = CurrentValueSubject<Double, Never>(0)
    public let bufferTimeValueSubject = CurrentValueSubject<Double, Never>(0)
    public let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.unknown)

    var isSeekInProgress = false
    var chaseTime = CMTime.zero
    var timeObserverToken: Any?
    var playerCurrentItemStatus: AVPlayerItem.Status = .unknown

    private(set) lazy var timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .dropLeading
        formatter.maximumUnitCount = 2

        return formatter
    }()

    private(set) var player: AVQueuePlayer?
    private(set) var playerItems: [AVPlayerItem] = []
    private var enqueueTask: Task<Void, Never>?

    public init() {}

    deinit {
        Task {
            await resetAndTerminatePlayer()
        }
    }

    public var isReady: Bool {
        if case .ready = status {
            return true
        } else {
            return false
        }
    }

    public var isPlaying: Bool {
        let rate = self.player?.rate ?? 0
        return rate > Float(0.0)
    }

    public var duration: Double {
        guard let currentItem = player?.currentItem else { return 0.0 }

        let durationInSeconds = CMTimeGetSeconds(currentItem.duration)
        return durationInSeconds.isNaN.not ? durationInSeconds : 0
    }

    public var currentTime: Double {
        guard let currentItem = player?.currentItem else { return 0.0 }

        let currentTimeInSeconds = CMTimeGetSeconds(currentItem.currentTime())
        return currentTimeInSeconds.isNaN.not ? currentTimeInSeconds : 0
    }

    public var rate: Float {
        return player?.rate ?? 0
    }

    public var status = PlaybackStatus.unknown {
        didSet {
            playbackStatusSubject.send(status)
            currentTimeSubject.send(currentTime)
            isPlayingSubject.send(status == .playing)

            if status == .stopped {
                resetTimerLabels()
            }
        }
    }

    private func resetTimerLabels() {
        timeElapsedSubject.send("--:--")
        timeRemaningSubject.send("--:--")
    }
}

extension AMMediaPlayer {

    private func resetAndTerminatePlayer() {
        player?.removeAllItems()
        player = nil
        removePeriodicTimeObserver()
    }

    private func loadAssets(assets: [AVURLAsset]) async throws -> [AVPlayerItem] {
        var playerItems: [AVPlayerItem] = []

        for asset in assets {
            try Task.checkCancellation()
            let playerItem = try await loadURLAsset(asset)
            playerItems.append(playerItem)
        }

        return playerItems
    }

    public func enqueue(urlAssets: [AVURLAsset] = [], startPlayingAutomatically: Bool = false) async throws {
        do {
            playerItems = try await loadAssets(assets: urlAssets)
            guard playerItems.isEmpty.not else { return }

            player = AVQueuePlayer(items: playerItems)
            player?.automaticallyWaitsToMinimizeStalling = true

            setupObservers()
            addPeriodicTimeObserver()
            durationSubject.send(duration)

            if startPlayingAutomatically {
                player?.play()
            }
        } catch is CancellationError {
            resetAndTerminatePlayer()
        }
    }
}

extension AMMediaPlayer.PlaybackStatus: Equatable {

    public static func ==(lhs: AMMediaPlayer.PlaybackStatus, rhs: AMMediaPlayer.PlaybackStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready):
            return true
        case (.buffering, .buffering):
            return true
        case (.waitingToPlay, .waitingToPlay):
            return true
        case (.playing, .playing):
            return true
        case (.paused, .paused):
            return true
        case (.itemChanged(let playerItem1), .itemChanged(let playerItem2)):
            return playerItem1 == playerItem2
        case (.stopped, .stopped):
            return true
        default:
            return false
        }
    }
}
