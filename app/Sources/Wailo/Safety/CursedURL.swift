import Foundation

enum CursedURL {
    static let keywords = ["kyc", "update-pan", "electricity-bill", "refund", "lottery"]

    static func isCursed(_ absoluteString: String) -> Bool {
        let folded = absoluteString.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return keywords.contains(where: folded.contains)
    }

    static func isCursed(_ url: URL) -> Bool {
        isCursed(url.absoluteString)
    }
}

/// Pure edge-triggered deduplication for the optional Safari watcher.
struct CursedURLDetector: Equatable, Sendable {
    private(set) var currentURL: String?
    private(set) var hasTriggeredForCurrentURL = false

    mutating func inspect(_ absoluteString: String?) -> Bool {
        guard let absoluteString else {
            currentURL = nil
            hasTriggeredForCurrentURL = false
            return false
        }
        if absoluteString != currentURL {
            currentURL = absoluteString
            hasTriggeredForCurrentURL = false
        }
        guard CursedURL.isCursed(absoluteString), !hasTriggeredForCurrentURL else { return false }
        hasTriggeredForCurrentURL = true
        return true
    }
}
