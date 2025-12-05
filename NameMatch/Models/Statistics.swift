import Foundation

struct Statistics: Codable {
    var totalSwipes: Int
    var totalLikes: Int
    var totalPasses: Int
    var matchCount: Int
    var partnerSwipes: Int

    init(
        totalSwipes: Int = 0,
        totalLikes: Int = 0,
        totalPasses: Int = 0,
        matchCount: Int = 0,
        partnerSwipes: Int = 0
    ) {
        self.totalSwipes = totalSwipes
        self.totalLikes = totalLikes
        self.totalPasses = totalPasses
        self.matchCount = matchCount
        self.partnerSwipes = partnerSwipes
    }

    var likeRate: Double {
        guard totalSwipes > 0 else { return 0 }
        return Double(totalLikes) / Double(totalSwipes)
    }

    var matchRate: Double {
        guard totalLikes > 0 else { return 0 }
        return Double(matchCount) / Double(totalLikes)
    }

    var swipeDifference: Int {
        totalSwipes - partnerSwipes
    }

    mutating func recordSwipe(liked: Bool) {
        totalSwipes += 1
        if liked {
            totalLikes += 1
        } else {
            totalPasses += 1
        }
    }

    mutating func recordMatch() {
        matchCount += 1
    }

    mutating func undoSwipe(liked: Bool) {
        totalSwipes = max(0, totalSwipes - 1)
        if liked {
            totalLikes = max(0, totalLikes - 1)
        } else {
            totalPasses = max(0, totalPasses - 1)
        }
    }
}
