import Foundation

struct Swipe: Codable, Identifiable, Equatable {
    let id: UUID
    let nameId: String
    let liked: Bool
    let userId: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        nameId: String,
        liked: Bool,
        userId: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.nameId = nameId
        self.liked = liked
        self.userId = userId
        self.timestamp = timestamp
    }
}

// For undo functionality
struct SwipeHistoryItem: Codable, Identifiable {
    let id: UUID
    let swipe: Swipe
    let name: BabyName

    init(swipe: Swipe, name: BabyName) {
        self.id = swipe.id
        self.swipe = swipe
        self.name = name
    }
}
