import Foundation
import CloudKit

@MainActor
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase

    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncError: String?

    // Record types
    private let householdRecordType = "Household"
    private let swipeRecordType = "Swipe"
    private let matchRecordType = "Match"
    private let memberRecordType = "HouseholdMember"
    private let dismissedMatchRecordType = "DismissedMatch"

    // Callbacks
    var onPartnerSwipesUpdated: (([Swipe]) -> Void)?
    var onMatchCreated: ((String) -> Void)?

    // MARK: - Init

    private init() {
        container = CKContainer(identifier: "iCloud.com.jacobdecker.NameMatch")
        database = container.publicCloudDatabase
    }

    // MARK: - Household Operations

    func createHousehold(_ household: Household) async throws {
        print("CloudKit: Creating household with code: \(household.code) in container: \(container.containerIdentifier ?? "unknown")")

        let record = CKRecord(recordType: householdRecordType)
        record["code"] = household.code as CKRecordValue
        record["memberIds"] = household.memberIds as CKRecordValue
        record["createdAt"] = household.createdAt as CKRecordValue

        do {
            let savedRecord = try await database.save(record)
            print("CloudKit: Household saved successfully with recordID: \(savedRecord.recordID)")
            print("CloudKit: Record zone: \(savedRecord.recordID.zoneID)")

            // DEBUG: Immediately verify the record exists
            do {
                let fetchedRecord = try await database.record(for: savedRecord.recordID)
                print("CloudKit: VERIFIED - Record exists with code: \(fetchedRecord["code"] as? String ?? "nil")")
            } catch {
                print("CloudKit: WARNING - Could not verify record exists: \(error)")
            }

            // Also register the creator as a member
            if let creatorId = household.memberIds.first {
                try await saveMember(userId: creatorId, householdCode: household.code)
            }
        } catch {
            print("CloudKit: Failed to save household - \(error)")
            throw error
        }
    }

    func findHousehold(byCode code: String) async throws -> Household? {
        let predicate = NSPredicate(format: "code == %@", code)
        let query = CKQuery(recordType: householdRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 1)

        guard let result = results.first else { return nil }
        let record = try result.1.get()

        return Household(
            id: UUID(),
            code: record["code"] as? String ?? code,
            memberIds: record["memberIds"] as? [String] ?? [],
            createdAt: record["createdAt"] as? Date ?? Date()
        )
    }

    func joinHousehold(code: String, userId: String) async throws -> Household? {
        // Find the household
        print("CloudKit: Searching for household with code: \(code) in container: \(container.containerIdentifier ?? "unknown")")
        let predicate = NSPredicate(format: "code == %@", code)
        let query = CKQuery(recordType: householdRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 1)
        print("CloudKit: Query returned \(results.count) results")

        // DEBUG: If query fails, try fetching ALL households to diagnose
        if results.isEmpty {
            print("CloudKit: DEBUG - Trying to fetch ALL households...")
            let allPredicate = NSPredicate(value: true)
            let allQuery = CKQuery(recordType: householdRecordType, predicate: allPredicate)
            let (allResults, _) = try await database.records(matching: allQuery, resultsLimit: 100)
            print("CloudKit: DEBUG - Found \(allResults.count) total households")
            for result in allResults {
                if let record = try? result.1.get() {
                    let recordCode = record["code"] as? String ?? "unknown"
                    print("CloudKit: DEBUG - Household code: \(recordCode)")
                    if recordCode == code {
                        print("CloudKit: DEBUG - FOUND IT! Index issue confirmed.")
                    }
                }
            }
        }

        guard let result = results.first else {
            print("CloudKit: No household found with code: \(code)")
            return nil
        }
        let record = try result.1.get()
        print("CloudKit: Found household record: \(record.recordID)")

        // Register this user as a member of the household (non-fatal if fails)
        do {
            try await saveMember(userId: userId, householdCode: code)
        } catch {
            print("CloudKit: WARNING - Failed to save member record (non-fatal): \(error)")
        }

        // Fetch all members to get accurate count
        var members: [String] = []
        do {
            members = try await fetchMembers(householdCode: code)
            print("CloudKit: Household now has \(members.count) members")
        } catch {
            print("CloudKit: WARNING - Failed to fetch members: \(error)")
            members = [userId] // At minimum, include this user
        }

        return Household(
            id: UUID(),
            code: code,
            memberIds: members,
            createdAt: record["createdAt"] as? Date ?? Date()
        )
    }

    // MARK: - Member Operations

    func saveMember(userId: String, householdCode: String) async throws {
        // Check if already a member
        let predicate = NSPredicate(format: "householdCode == %@ AND userId == %@", householdCode, userId)
        let query = CKQuery(recordType: memberRecordType, predicate: predicate)
        let (existing, _) = try await database.records(matching: query, resultsLimit: 1)

        if existing.isEmpty {
            let record = CKRecord(recordType: memberRecordType)
            record["householdCode"] = householdCode as CKRecordValue
            record["userId"] = userId as CKRecordValue
            record["joinedAt"] = Date() as CKRecordValue
            try await database.save(record)
            print("CloudKit: Saved member record for user \(userId) in household \(householdCode)")
        } else {
            print("CloudKit: User \(userId) already a member of household \(householdCode)")
        }
    }

    func fetchMembers(householdCode: String) async throws -> [String] {
        let predicate = NSPredicate(format: "householdCode == %@", householdCode)
        let query = CKQuery(recordType: memberRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 10)

        return results.compactMap { result -> String? in
            guard let record = try? result.1.get() else { return nil }
            return record["userId"] as? String
        }
    }

    func deleteMember(userId: String, householdCode: String) async throws {
        let predicate = NSPredicate(format: "householdCode == %@ AND userId == %@", householdCode, userId)
        let query = CKQuery(recordType: memberRecordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, resultsLimit: 1)

        for result in results {
            if let record = try? result.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                print("CloudKit: Deleted member record for user \(userId)")
            }
        }
    }

    // MARK: - Swipe Operations

    func saveSwipe(_ swipe: Swipe, householdCode: String) async throws {
        let record = CKRecord(recordType: swipeRecordType)
        record["householdCode"] = householdCode as CKRecordValue
        record["nameId"] = swipe.nameId as CKRecordValue
        record["liked"] = (swipe.liked ? 1 : 0) as CKRecordValue
        record["userId"] = swipe.userId as CKRecordValue
        record["timestamp"] = swipe.timestamp as CKRecordValue

        try await database.save(record)
    }

    func fetchPartnerSwipes(householdCode: String, excludingUserId: String) async throws -> [Swipe] {
        let predicate = NSPredicate(
            format: "householdCode == %@ AND userId != %@",
            householdCode, excludingUserId
        )
        let query = CKQuery(recordType: swipeRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 10000)

        return results.compactMap { result -> Swipe? in
            guard let record = try? result.1.get() else { return nil }
            return Swipe(
                id: UUID(),
                nameId: record["nameId"] as? String ?? "",
                liked: (record["liked"] as? Int ?? 0) == 1,
                userId: record["userId"] as? String ?? "",
                timestamp: record["timestamp"] as? Date ?? Date()
            )
        }
    }

    // MARK: - Match Operations

    func saveMatch(_ match: Match, householdCode: String) async throws {
        let record = CKRecord(recordType: matchRecordType)
        record["householdCode"] = householdCode as CKRecordValue
        record["nameId"] = match.nameId as CKRecordValue
        record["matchedAt"] = match.matchedAt as CKRecordValue

        try await database.save(record)
    }

    func fetchMatches(householdCode: String) async throws -> [Match] {
        let predicate = NSPredicate(format: "householdCode == %@", householdCode)
        let query = CKQuery(recordType: matchRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "matchedAt", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 500)

        return results.compactMap { result -> Match? in
            guard let record = try? result.1.get() else { return nil }
            return Match(
                id: UUID(),
                nameId: record["nameId"] as? String ?? "",
                matchedAt: record["matchedAt"] as? Date ?? Date()
            )
        }
    }

    func deleteMatch(nameId: String, householdCode: String) async throws {
        let predicate = NSPredicate(format: "householdCode == %@ AND nameId == %@", householdCode, nameId)
        let query = CKQuery(recordType: matchRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 1)

        for result in results {
            if let record = try? result.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                print("CloudKit: Deleted match for nameId: \(nameId)")
            }
        }
    }

    func deleteAllMatches(householdCode: String) async throws {
        let predicate = NSPredicate(format: "householdCode == %@", householdCode)
        let query = CKQuery(recordType: matchRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 500)

        var matchesDeleted = 0
        for result in results {
            if let record = try? result.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                matchesDeleted += 1
            }
        }

        print("CloudKit: Deleted \(matchesDeleted) matches for household \(householdCode)")
    }

    func deleteAllUserData(userId: String, householdCode: String) async throws {
        // Delete all swipes for this user (but keep dismissed matches so partner sees them)
        let swipePredicate = NSPredicate(format: "householdCode == %@ AND userId == %@", householdCode, userId)
        let swipeQuery = CKQuery(recordType: swipeRecordType, predicate: swipePredicate)
        let (swipeResults, _) = try await database.records(matching: swipeQuery, resultsLimit: 10000)

        var swipesDeleted = 0
        for result in swipeResults {
            if let record = try? result.1.get() {
                try await database.deleteRecord(withID: record.recordID)
                swipesDeleted += 1
            }
        }

        print("CloudKit: Deleted \(swipesDeleted) swipes for user \(userId)")
    }

    // MARK: - Dismissed Match Operations

    func saveDismissedMatch(nameId: String, userId: String, householdCode: String) async throws {
        // Use deterministic record ID to avoid duplicates without needing to query
        let recordID = CKRecord.ID(recordName: "dismissed_\(householdCode)_\(nameId)_\(userId)")
        let record = CKRecord(recordType: dismissedMatchRecordType, recordID: recordID)
        record["householdCode"] = householdCode as CKRecordValue
        record["nameId"] = nameId as CKRecordValue
        record["userId"] = userId as CKRecordValue
        record["dismissedAt"] = Date() as CKRecordValue
        try await database.save(record)
        print("CloudKit: Saved dismissed match for nameId: \(nameId)")
    }

    func fetchPartnerDismissedMatches(householdCode: String, excludingUserId: String) async throws -> Set<String> {
        let predicate = NSPredicate(format: "householdCode == %@ AND userId != %@", householdCode, excludingUserId)
        let query = CKQuery(recordType: dismissedMatchRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 500)

        let nameIds = results.compactMap { result -> String? in
            guard let record = try? result.1.get() else { return nil }
            return record["nameId"] as? String
        }

        return Set(nameIds)
    }

    // MARK: - Full Sync

    func performFullSync(
        householdCode: String,
        userId: String,
        localSwipes: [Swipe],
        localMatches: [Match]
    ) async throws -> (partnerSwipes: [Swipe], allMatches: [Match]) {
        isSyncing = true
        syncError = nil

        defer {
            isSyncing = false
            lastSyncTime = Date()
        }

        do {
            // Note: Swipes are already uploaded immediately when created (in AppStore.swipe()),
            // so we don't need to upload them again here to avoid creating duplicates

            // Fetch partner's swipes
            let partnerSwipes = try await fetchPartnerSwipes(
                householdCode: householdCode,
                excludingUserId: userId
            )

            // Fetch all matches
            let remoteMatches = try await fetchMatches(householdCode: householdCode)

            // Detect new matches
            let localLikedIds = Set(localSwipes.filter { $0.liked }.map { $0.nameId })
            let partnerLikedIds = Set(partnerSwipes.filter { $0.liked }.map { $0.nameId })
            let existingMatchIds = Set(remoteMatches.map { $0.nameId })

            let newMatchIds = localLikedIds.intersection(partnerLikedIds).subtracting(existingMatchIds)

            // Save new matches
            for nameId in newMatchIds {
                let match = Match(nameId: nameId)
                try await saveMatch(match, householdCode: householdCode)
            }

            // Fetch updated matches
            let allMatches = try await fetchMatches(householdCode: householdCode)

            return (partnerSwipes, allMatches)

        } catch {
            syncError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Subscription (for real-time updates)

    func setupSubscriptions(householdCode: String) async throws {
        // Swipe subscription
        let swipePredicate = NSPredicate(format: "householdCode == %@", householdCode)
        let swipeSubscription = CKQuerySubscription(
            recordType: swipeRecordType,
            predicate: swipePredicate,
            options: [.firesOnRecordCreation]
        )

        let swipeNotification = CKSubscription.NotificationInfo()
        swipeNotification.shouldSendContentAvailable = true
        swipeSubscription.notificationInfo = swipeNotification

        // Match subscription
        let matchPredicate = NSPredicate(format: "householdCode == %@", householdCode)
        let matchSubscription = CKQuerySubscription(
            recordType: matchRecordType,
            predicate: matchPredicate,
            options: [.firesOnRecordCreation]
        )

        let matchNotification = CKSubscription.NotificationInfo()
        matchNotification.alertBody = "You have a new name match!"
        matchNotification.shouldBadge = true
        matchNotification.soundName = "default"
        matchSubscription.notificationInfo = matchNotification

        try await database.save(swipeSubscription)
        try await database.save(matchSubscription)
    }
}
