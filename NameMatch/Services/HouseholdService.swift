import Foundation

@MainActor
class HouseholdService: ObservableObject {
    static let shared = HouseholdService()

    private let cloudSync = CloudSyncService.shared

    @Published var isCreating = false
    @Published var isJoining = false
    @Published var error: String?

    private init() {}

    // MARK: - Create Household

    func createHousehold(userId: String) async -> Household? {
        isCreating = true
        error = nil

        defer { isCreating = false }

        let household = Household(memberIds: [userId])

        do {
            try await cloudSync.createHousehold(household)
            return household
        } catch {
            self.error = "Failed to create household: \(error.localizedDescription)"
            // Return local household anyway for offline support
            return household
        }
    }

    // MARK: - Join Household

    func joinHousehold(code: String, userId: String) async -> Household? {
        isJoining = true
        error = nil

        defer { isJoining = false }

        do {
            if let household = try await cloudSync.joinHousehold(code: code, userId: userId) {
                return household
            } else {
                error = "No household found with that code"
                return nil
            }
        } catch {
            self.error = "Failed to join household: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Verify Household

    func verifyHousehold(code: String) async -> Bool {
        do {
            let household = try await cloudSync.findHousehold(byCode: code)
            return household != nil
        } catch {
            return false
        }
    }

    // MARK: - Check Partner Status

    func checkPartnerStatus(householdCode: String, userId: String) async -> Bool {
        do {
            if let household = try await cloudSync.findHousehold(byCode: householdCode) {
                return household.memberIds.contains { $0 != userId }
            }
            return false
        } catch {
            return false
        }
    }
}
