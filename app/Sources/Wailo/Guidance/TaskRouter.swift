import Foundation

enum Route: Equatable, Sendable {
    case newFolder
    case safari
    case cursed
    case ghostMail
    case grimoire
    case live(String)
    case nothing
}

enum TaskRouter {
    private static let groups: [(Set<String>, Route)] = [
        (["folder"], .newFolder),
        (["safari", "website", "wikipedia", "browse"], .safari),
        (["scam", "cursed"], .cursed),
        (["mail", "letter", "aarav"], .ghostMail),
        (["grimoire", "spell"], .grimoire)
    ]

    static func route(_ input: String) -> Route {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .nothing }
        let tokenSet = Set(tokens(in: trimmed))
        for (terms, route) in groups where !terms.isDisjoint(with: tokenSet) {
            return route
        }
        return .live(trimmed)
    }

    static func tokens(in input: String) -> [String] {
        let folded = input.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        var tokens: [String] = []
        var current = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
