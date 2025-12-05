import Foundation

struct Household: Codable, Equatable {
    let id: UUID
    let code: String
    var memberIds: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        code: String? = nil,
        memberIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.code = code ?? Household.generateCode()
        self.memberIds = memberIds
        self.createdAt = createdAt
    }

    var partnerJoined: Bool {
        memberIds.count >= 2
    }

    mutating func addMember(_ memberId: String) {
        if !memberIds.contains(memberId) {
            memberIds.append(memberId)
        }
    }

    func partnerId(for userId: String) -> String? {
        memberIds.first { $0 != userId }
    }

    // Generate a 6-character code without ambiguous characters (0/O, 1/l/I)
    static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
