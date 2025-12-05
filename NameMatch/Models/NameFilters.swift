import Foundation

struct NameFilters: Codable, Equatable {
    var genders: Set<Gender>
    var origins: Set<Origin>
    var styles: Set<Style>
    var firstLetters: Set<String>
    var popularities: Set<Popularity>

    init(
        genders: Set<Gender> = Set(Gender.allCases),
        origins: Set<Origin> = [],
        styles: Set<Style> = [],
        firstLetters: Set<String> = [],
        popularities: Set<Popularity> = Set(Popularity.allCases)
    ) {
        self.genders = genders
        self.origins = origins
        self.styles = styles
        self.firstLetters = firstLetters
        self.popularities = popularities
    }

    static let `default` = NameFilters()

    var isDefault: Bool {
        genders == Set(Gender.allCases) &&
        origins.isEmpty &&
        styles.isEmpty &&
        firstLetters.isEmpty &&
        popularities == Set(Popularity.allCases)
    }

    var activeFilterCount: Int {
        var count = 0
        if genders != Set(Gender.allCases) { count += 1 }
        if !origins.isEmpty { count += 1 }
        if !styles.isEmpty { count += 1 }
        if !firstLetters.isEmpty { count += 1 }
        if popularities != Set(Popularity.allCases) { count += 1 }
        return count
    }

    func matches(_ name: BabyName) -> Bool {
        // Gender filter
        if !genders.contains(name.gender) {
            return false
        }

        // Origin filter (if any selected, name must have at least one)
        if !origins.isEmpty {
            let hasMatchingOrigin = name.origins.contains { origins.contains($0) }
            if !hasMatchingOrigin {
                return false
            }
        }

        // Style filter (if any selected, name must have at least one)
        if !styles.isEmpty {
            let hasMatchingStyle = name.styles.contains { styles.contains($0) }
            if !hasMatchingStyle {
                return false
            }
        }

        // First letter filter
        if !firstLetters.isEmpty {
            let firstLetter = String(name.name.prefix(1)).uppercased()
            if !firstLetters.contains(firstLetter) {
                return false
            }
        }

        // Popularity filter
        if !popularities.contains(name.popularity) {
            return false
        }

        return true
    }
}
