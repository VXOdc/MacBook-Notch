import IOKit.ps
import SwiftUI

/// Reads the built-in battery percentage.
final class BatteryMonitor: ObservableObject {
    @Published var percent: Int = 100

    private var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    deinit { timer?.invalidate() }

    var symbol: String {
        switch percent {
        case 90...: return "battery.100"
        case 65...: return "battery.75"
        case 40...: return "battery.50"
        case 15...: return "battery.25"
        default:    return "battery.0"
        }
    }

    private func update() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for ps in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
               let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
                let p = Int((Double(capacity) / Double(max) * 100).rounded())
                DispatchQueue.main.async { self.percent = p }
                return
            }
        }
    }
}
