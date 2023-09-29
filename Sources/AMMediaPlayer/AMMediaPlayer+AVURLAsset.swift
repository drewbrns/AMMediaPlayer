//
//  Created by Drew Barnes on 05/05/2023.
//

import AVFoundation
import Foundation

extension AMMediaPlayer {

    public enum AssetLoadingError: Error {
        case protectedAsset
        case failureToPlayAsset
    }

    func loadURLAsset(_ newAsset: AVURLAsset) async throws -> AVPlayerItem {
        await newAsset.loadValues(forKeys: ["duration", "tracks"])

        if newAsset.isPlayable.not {
            throw AssetLoadingError.failureToPlayAsset
        }

        if newAsset.hasProtectedContent {
            throw AssetLoadingError.protectedAsset
        }

        return AVPlayerItem(asset: newAsset)
    }
}
