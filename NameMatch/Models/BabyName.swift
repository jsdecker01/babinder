import Foundation

struct BabyName: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let gender: Gender
    let origins: [Origin]
    let styles: [Style]
    let meaning: String?
    let popularity: Popularity

    init(
        id: String? = nil,
        name: String,
        gender: Gender,
        origins: [Origin] = [],
        styles: [Style] = [],
        meaning: String? = nil,
        popularity: Popularity = .common
    ) {
        self.id = id ?? name.lowercased()
        self.name = name
        self.gender = gender
        self.origins = origins
        self.styles = styles
        self.meaning = meaning
        self.popularity = popularity
    }
}

// MARK: - Gender

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case neutral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Boy"
        case .female: return "Girl"
        case .neutral: return "Neutral"
        }
    }

    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .neutral: return "figure.2"
        }
    }
}

// MARK: - Origin

enum Origin: String, Codable, CaseIterable, Identifiable {
    case english
    case hebrew
    case greek
    case latin
    case irish
    case spanish
    case german
    case french
    case arabic
    case indian
    case japanese
    case african
    case scottish
    case italian
    case scandinavian
    case slavic
    case welsh
    case persian
    case chinese
    case korean
    case portuguese
    case hawaiian
    case sanskrit
    case aramaic
    case celtic
    case dutch
    case nativeAmerican = "native american"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nativeAmerican: return "Native American"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - Style

enum Style: String, Codable, CaseIterable, Identifiable {
    case classic
    case modern
    case unique
    case biblical
    case nature
    case literary
    case royal
    case mythological
    case vintage
    case trendy
    case strong
    case gentle
    case artistic
    case scientific

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Popularity

enum Popularity: String, Codable, CaseIterable, Identifiable {
    case popular
    case common
    case uncommon
    case rare

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .popular: return "Top 100"
        case .common: return "Well-known"
        case .uncommon: return "Less common"
        case .rare: return "Unique find"
        }
    }
}
