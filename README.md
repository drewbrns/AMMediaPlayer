# AMMediaPlayer

A simple and lightweight wrapper around AVQueuePlayer with the aim of audio streaming simple and decoupled from your main code

# Installation



# Basic Usage



```
import AMMediaPlayer

let urlAssets = [
    AVURLAsset(url: audioUrl, options: nil) // audioUrl can be a local url or a remote url
]

await AMMediaPlayer.shared.enqueue(urlAssets: urlAssets)

AMMediaPlayer.shared.play()

```