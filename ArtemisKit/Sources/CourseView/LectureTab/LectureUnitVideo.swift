//
//  LectureUnitVideo.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.11.24.
//

import AVKit
import DesignLibrary
import SharedModels
import SwiftUI

struct VideoUnitSheetContent: View {

    let unit: AttachmentVideoUnit
    let videoSource: URL
    var canPlayInline: Bool {
        let supportedExtensions = ["m3u8", "mp4"]
        return supportedExtensions.contains(videoSource.pathExtension)
    }

    var body: some View {
        GeometryReader { proxy in
            if let description = unit.description {
                HStack {
                    VStack(alignment: .leading) {
                        Text(R.string.localizable.description())
                            .font(.headline)
                        Text(description)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }

            if canPlayInline {
                VideoPlayerView(url: videoSource)
                    .frame(width: proxy.size.width,
                           height: min(proxy.size.height, proxy.size.width * 9 / 16))
            }

            Link(R.string.localizable.openVideo(), destination: videoSource)
                .buttonStyle(ArtemisButton())
                .padding(.horizontal)
        }
    }
}

// Custom video player, because the default one doesn't allow full screen
private struct VideoPlayerView: UIViewControllerRepresentable {

    var url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerView>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.videoGravity = .resizeAspect

        let player = AVPlayer(url: url)
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.play()

        controller.player = player

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerView>) {
    }
}
