//
//  Created by Drew Barnes on 29/09/2023.
//

import AVFoundation

extension AMMediaPlayer {

    public func play() {
        addPeriodicTimeObserver()
        player?.play()
    }

    public func pause() {
        removePeriodicTimeObserver()
        player?.pause()
    }

    public func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func skipToNext() {
        player?.advanceToNextItem()
    }

    public func skipToItem(at index: Int) async {

        guard playerItems.count > index else { return }

        pause()

        let newItems = Array(playerItems[index...])
        reloadPlayer(with: newItems)

        play()
    }

    public func seek(to seconds: Int) async {
        let targetTime = CMTimeMake(value: Int64(seconds), timescale: 1)
        await stopPlayingAndSeekSmoothlyToTime(newChaseTime: targetTime)
    }

    public func rev(seek: Int = 15) async {
        guard let player = player else { return }

        let targetTime = CMTimeMake(value: Int64(seek), timescale: 1)
        let newCurrentTime = player.currentTime() - targetTime

        let seekToNewTime = CMTimeGetSeconds(newCurrentTime) < 0 ? .zero : newCurrentTime
        let completed = await player.seek(to: seekToNewTime)
        if completed {
            updateTimestamps(with: newCurrentTime)
        }
    }

    public func skip(seek: Int = 30) async {
        guard let player = player else { return }

        let targetTime = CMTimeMake(value: Int64(seek), timescale: 1)
        let newCurrentTime = targetTime + player.currentTime()

        if CMTimeGetSeconds(newCurrentTime) >= duration {
            skipToNext()
        } else {
            let completed = await player.seek(to: newCurrentTime)
            if completed {
                updateTimestamps(with: newCurrentTime)
            }
        }
    }

    private func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) async {
        if isSeekInProgress {
            player?.pause()
        } else {
            player?.play()
        }

        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            if isSeekInProgress.not {
                await trySeekToChaseTime()
            }
        }
    }

    private func trySeekToChaseTime() async {
        if playerCurrentItemStatus == .readyToPlay {
            await actuallySeekToTime()
        }
    }

    private func actuallySeekToTime() async {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime

        let _ = await player?.seek(to: seekTimeInProgress, toleranceBefore: .zero, toleranceAfter: .zero)
        if CMTimeCompare(seekTimeInProgress, chaseTime) == 0 {
            isSeekInProgress = false
            updateTimestamps(with: seekTimeInProgress)
            player?.play()
        } else {
            await trySeekToChaseTime()
        }
    }
}
