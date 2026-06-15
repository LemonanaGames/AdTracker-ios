import SwiftUI

/// Holds the selected visual direction + accent override and resolves the active `Theme`.
/// Persisted in UserDefaults (App Group container in later phases).
@MainActor @Observable
final class ThemeStore {
    var directionKey: String {
        didSet { defaults.set(directionKey, forKey: Keys.direction) }
    }
    /// Accent hex, or "default" to use the direction's own accent.
    var accentHex: String {
        didSet { defaults.set(accentHex, forKey: Keys.accent) }
    }

    private let defaults: UserDefaults
    private enum Keys { static let direction = "theme.direction", accent = "theme.accent" }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.directionKey = defaults.string(forKey: Keys.direction) ?? Theme.midnight.key
        self.accentHex = defaults.string(forKey: Keys.accent) ?? "default"
    }

    var theme: Theme { Theme.named(directionKey).applyingAccent(accentHex) }

    /// Cycles Midnight → Graphite → Mist (the Settings → Appearance row).
    func cycleDirection() {
        let order = ["midnight", "graphite", "mist"]
        let i = order.firstIndex(of: directionKey) ?? 0
        directionKey = order[(i + 1) % order.count]
    }
}

// MARK: - Environment injection (mirrors the design's ThemeCtx)

extension EnvironmentValues {
    @Entry var theme: Theme = .midnight
}
