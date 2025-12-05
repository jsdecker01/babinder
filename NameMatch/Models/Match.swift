import Foundation

struct Match: Codable, Identifiable, Equatable {
    let id: UUID
    let nameId: String
    let matchedAt: Date
    var rating: Int?  // 1-5 hearts, nil = unrated
    var notes: String?

    init(
        id: UUID = UUID(),
        nameId: String,
        matchedAt: Date = Date(),
        rating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.nameId = nameId
        self.matchedAt = matchedAt
        self.rating = rating
        self.notes = notes
    }
}
