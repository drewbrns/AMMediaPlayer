//
//  Created by Drew Barnes on 29/09/2023.
//

import AVFoundation

@MainActor
public protocol Player {

    var isPlaying: Bool { get }
    var isReady: Bool { get }
    var duration: Double { get }
    var currentTime: Double { get }
    var rate: Float { get }
    var nowPlaying: AVPlayerItem? { get }
    var status: AMMediaPlayer.PlaybackStatus { get set }

    func enqueue(urlAssets: [AVURLAsset], startPlayingAutomatically: Bool) async throws
    func reloadPlayer()

    func play()
    func pause()
    func togglePlayback()

    func skipToNext()
    func skipToItem(at index: Int) async
    func seek(to seconds: Int) async
    func rev(seek: Int) async
    func skip(seek: Int) async
}
