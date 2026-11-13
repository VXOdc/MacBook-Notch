import SwiftUI

/// The black capsule shape: square corners at the top (flush with the screen
/// edge), rounded corners at the bottom, like the physical notch.
struct NotchShape: Shape {
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - radius))
        path.addQuadCurve(to: CGPoint(x: w - radius, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: radius, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - radius), control: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

/// Small animated equalizer bars shown while audio is playing.
struct EqualizerBars: View {
    var playing: Bool
    @State private var animate = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 3, height: animate ? [12, 7, 10][i] : [5, 11, 6][i])
                    .animation(
                        playing
                            ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true).delay(Double(i) * 0.12)
                            : .default,
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

struct NotchView: View {
    @ObservedObject var nowPlaying: NowPlaying
    var collapsedWidth: CGFloat
    var collapsedHeight: CGFloat
    var onResize: (CGFloat, CGFloat) -> Void

    @StateObject private var battery = BatteryMonitor()
    @State private var expanded = false
    @State private var now = Date()
    @State private var hoverTask: Task<Void, Never>?

    private let expandedWidth: CGFloat = 400
    private let expandedHeight: CGFloat = 176
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentWidth: CGFloat { expanded ? expandedWidth : collapsedWidth }
    private var currentHeight: CGFloat { expanded ? expandedHeight : collapsedHeight }

    var body: some View {
        ZStack {
            NotchShape(radius: expanded ? 26 : 12).fill(Color.black)
            if expanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .frame(width: currentWidth, height: currentHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: expanded)
        .onHover(perform: handleHover)
        .onTapGesture {
            hoverTask?.cancel()
            expanded.toggle()
        }
        .onChange(of: expanded) { _ in onResize(currentWidth, currentHeight) }
        .onReceive(clockTimer) { now = $0 }
    }

    // MARK: - Collapsed

    private var collapsedContent: some View {
        HStack(spacing: 6) {
            if let track = nowPlaying.track, !track.title.isEmpty {
                EqualizerBars(playing: track.playing)
                    .frame(width: 16, height: 12)
                Text(track.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text(now, style: .time)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Image(systemName: battery.symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text("\(battery.percent)%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        Group {
            if let track = nowPlaying.track, !track.title.isEmpty {
                mediaCard(track)
            } else {
                idleCard
            }
        }
        .padding(16)
    }

    private func mediaCard(_ track: NowPlaying.Track) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                if let art = track.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(track.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Text(track.artist.isEmpty ? track.album : track.artist)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)

                if track.duration > 0 {
                    HStack(spacing: 8) {
                        Text(timeString(track.elapsed))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.15))
                                Capsule()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: max(4, geo.size.width * CGFloat(min(1, track.elapsed / max(track.duration, 0.001)))))
                            }
                        }
                        .frame(height: 4)
                        Text(timeString(track.duration))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                HStack(spacing: 26) {
                    Button { nowPlaying.previous() } label: {
                        Image(systemName: "backward.fill").font(.system(size: 16))
                    }
                    Button { nowPlaying.togglePlayPause() } label: {
                        Image(systemName: track.playing ? "pause.fill" : "play.fill").font(.system(size: 20))
                    }
                    Button { nowPlaying.next() } label: {
                        Image(systemName: "forward.fill").font(.system(size: 16))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
            }
        }
    }

    private var idleCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 26))
                .foregroundStyle(Color.white.opacity(0.5))
            Text("Nothing playing")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.6))
            Text("\(battery.percent)% battery")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.4))
        }
    }

    // MARK: - Behavior

    private func handleHover(_ hovering: Bool) {
        if hovering {
            hoverTask?.cancel()
            if !expanded { expanded = true }
        } else {
            hoverTask?.cancel()
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                expanded = false
            }
        }
    }

    private func timeString(_ seconds: Double) -> String {
        let sec = Int(seconds.rounded())
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }
}
