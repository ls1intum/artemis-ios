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

    let videoUnit: VideoUnit
    var canPlayInline: Bool {
        let supportedExtensions = ["m3u8", "mp4"]
        guard let source = videoUnit.source,
              let url = URL(string: source) else {
            return false
        }
        return supportedExtensions.contains(url.pathExtension)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                if let description = videoUnit.description {
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

                if let source = videoUnit.source,
                   let url = URL(string: source) {
                    if canPlayInline {
                        VideoPlayerView(url: url)
                            .frame(width: proxy.size.width,
                                   height: min(proxy.size.height, proxy.size.width * 9 / 16))
                    }

                    Link(R.string.localizable.openVideo(), destination: url)
                        .buttonStyle(ArtemisButton())
                        .padding(.horizontal)
                } else {
                    Text(R.string.localizable.videoCouldNotBeLoaded())
                        .foregroundColor(.red)
                }
            }
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
