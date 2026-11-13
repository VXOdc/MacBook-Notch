import AppKit
import Combine
import Darwin
import Foundation

/// Reads "Now Playing" media info and sends playback commands using the same
/// system MediaRemote framework that macOS media keys and commercial notch
/// apps rely on. Loaded dynamically so the app works without any entitlements.
final class NowPlaying: ObservableObject {

    struct Track {
        var title = ""
        var artist = ""
        var album = ""
        var artwork: NSImage?
        var duration: Double = 0
        var elapsed: Double = 0
        var playing = false
    }

    @Published private(set) var track: Track?

    private var handle: UnsafeMutableRawPointer?
    private var timer: Timer?

    private typealias GetInfo = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias SendCommand = @convention(c) (Int32, NSDictionary?) -> Void
    private var getInfo: GetInfo?
    private var sendCommand: SendCommand?

    init() {
        handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote", RTLD_LAZY)
        guard let handle else { return }
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getInfo = unsafeBitCast(sym, to: GetInfo.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(sym, to: SendCommand.self)
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
        if let handle = handle { dlclose(handle) }
    }

    func refresh() {
        guard let getInfo else {
            track = nil
            return
        }
        getInfo(DispatchQueue.main) { [weak self] info in
            guard let self else { return }
            guard !info.isEmpty else {
                self.track = nil
                return
            }
            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            if title.isEmpty {
                self.track = nil
                return
            }
            var t = Track()
            t.title = title
            t.artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            t.album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            if let data = info["kMRMediaRemoteNowPlayingInfoArtwork"] as? Data {
                t.artwork = NSImage(data: data)
            } else if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                t.artwork = NSImage(data: data)
            } else if let image = info["kMRMediaRemoteNowPlayingInfoArtwork"] as? NSImage {
                t.artwork = image
            }
            t.duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
            t.elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
            t.playing = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0) > 0.01
            self.track = t
        }
    }

    // MARK: - Commands

    func togglePlayPause() { sendCommand?(2, nil) }
    func next() { sendCommand?(4, nil) }
    func previous() { sendCommand?(5, nil) }
}
