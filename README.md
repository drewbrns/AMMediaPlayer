# AMMediaPlayer

A simple and lightweight wrapper around AVQueuePlayer with the aim of making audio streaming simple and decoupled from your main code

# Installation
AMMediaPlayer can be installed via [Swift Package Manager](https://www.swift.org/package-manager/). 

# Basic Usage
```
// Import library
import AMMediaPlayer

// Prepare the assets you want to play
let urlAssets = [
    AVURLAsset(url: audioUrl, options: nil) // audioUrl can be a local url or a remote url
]

// Load the assets in the player

do {
    try await AMMediaPlayer.shared.enqueue(urlAssets: urlAssets)
} catch {
    // Handle Errors
}

// Play the asset
AMMediaPlayer.shared.play()

```

# Minimum Requirements
iOS 13

# License
AMMediaPlayer is available under the MIT license. See the LICENSE file for more info.