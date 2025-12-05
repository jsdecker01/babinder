import Foundation
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    static let shared = AppStore()

    // MARK: - Published Properties

    @Published var household: Household?
    @Published var swipes: [Swipe] = []
    @Published var matches: [Match] = []
    @Published var filters: NameFilters = .default
    @Published var statistics: Statistics = Statistics()
    @Published var partnerSwipes: [Swipe] = []

    @Published var currentNameQueue: [BabyName] = []
    @Published var isLoading = false
    @Published var showMatchCelebration = false
    @Published var lastMatchedName: BabyName?
    @Published var partnerDismissedMatchIds: Set<String> = []

    // Undo history (max 5)
    @Published private(set) var undoHistory: [SwipeHistoryItem] = []
    private let maxUndoCount = 5

    // MARK: - Private Properties

    private let nameDatabase = NameDatabase.shared
    private let cloudSync = CloudSyncService.shared
    private let userIdKey = "userId"
    private let swipesKey = "swipes"
    private let matchesKey = "matches"
    private let filtersKey = "filters"
    private let householdKey = "household"
    private let statisticsKey = "statistics"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let dismissedMatchesKey = "dismissedMatches"

    // Track dismissed matches so they don't get recreated
    private var dismissedMatchIds: Set<String> = []

    // MARK: - Computed Properties

    var userId: String {
        if let id = UserDefaults.standard.string(forKey: userIdKey) {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: userIdKey)
        return newId
    }

    var needsOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    var swipedNameIds: Set<String> {
        Set(swipes.map { $0.nameId })
    }

    var likedNameIds: Set<String> {
        Set(swipes.filter { $0.liked }.map { $0.nameId })
    }

    var matchedNameIds: Set<String> {
        Set(matches.map { $0.nameId })
    }

    var partnerLikedIds: Set<String> {
        Set(partnerSwipes.filter { $0.liked }.map { $0.nameId })
    }

    var remainingNames: Int {
        nameDatabase.filteredNames(with: filters, excluding: swipedNameIds).count
    }

    var canUndo: Bool {
        !undoHistory.isEmpty
    }

    var matchedNames: [BabyName] {
        matches
            .sorted { $0.matchedAt > $1.matchedAt }
            .compactMap { nameDatabase.name(for: $0.nameId) }
    }

    // MARK: - Init

    private init() {
        loadLocalData()
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
        objectWillChange.send()
    }

    func createHousehold() {
        let newHousehold = Household(memberIds: [userId])
        household = newHousehold
        saveLocal()

        // Save to CloudKit
        Task {
            do {
                try await cloudSync.createHousehold(newHousehold)
                print("Household created in CloudKit: \(newHousehold.code)")
                startAutoSync()
            } catch {
                print("Failed to create household in CloudKit: \(error)")
            }
        }
    }

    func joinHousehold(code: String) async -> Bool {
        do {
            // Try to find and join existing household in CloudKit
            if let joinedHousehold = try await cloudSync.joinHousehold(code: code, userId: userId) {
                household = joinedHousehold
                saveLocal()
                print("Joined household from CloudKit: \(code), members: \(joinedHousehold.memberIds.count)")

                // Sync partner's swipes and start auto-sync
                await syncWithCloud()
                startAutoSync()
                return true
            } else {
                // Household not found - could be offline or doesn't exist
                print("Household not found in CloudKit: \(code)")
                return false
            }
        } catch {
            print("Error joining household: \(error)")
            return false
        }
    }

    func leaveHousehold() {
        // Delete CloudKit records before leaving so partner sees changes
        if let householdCode = household?.code {
            Task { @MainActor in
                do {
                    // Mark all matches as dismissed by this user so partner sees "partner removed"
                    for match in matches {
                        try await cloudSync.saveDismissedMatch(nameId: match.nameId, userId: userId, householdCode: householdCode)
                        print("leaveHousehold: Marked match \(match.nameId) as dismissed by \(userId)")
                    }

                    // Delete all matches from CloudKit
                    try await cloudSync.deleteAllMatches(householdCode: householdCode)
                    print("leaveHousehold: Deleted all matches for household")

                    // Delete user's swipe data
                    try await cloudSync.deleteAllUserData(userId: userId, householdCode: householdCode)
                    print("leaveHousehold: Deleted swipe records for user \(userId)")

                    // Delete member record so partner sees "waiting for partner"
                    try await cloudSync.deleteMember(userId: userId, householdCode: householdCode)
                    print("leaveHousehold: Deleted member record for user \(userId)")
                } catch {
                    print("leaveHousehold: Failed to delete CloudKit records: \(error)")
                }

                // Now clear local data after CloudKit cleanup
                await MainActor.run {
                    stopAutoSync()
                    household = nil
                    partnerSwipes = []
                    matches = []
                    dismissedMatchIds = []
                    partnerDismissedMatchIds = []
                    statistics.partnerSwipes = 0
                    statistics.matchCount = 0
                    UserDefaults.standard.removeObject(forKey: householdKey)
                    UserDefaults.standard.removeObject(forKey: matchesKey)
                    UserDefaults.standard.removeObject(forKey: dismissedMatchesKey)
                    saveLocal()
                }
            }
        } else {
            // No household to clean up - just clear local data
            stopAutoSync()
            household = nil
            partnerSwipes = []
            matches = []
            dismissedMatchIds = []
            partnerDismissedMatchIds = []
            statistics.partnerSwipes = 0
            statistics.matchCount = 0
            UserDefaults.standard.removeObject(forKey: householdKey)
            UserDefaults.standard.removeObject(forKey: matchesKey)
            UserDefaults.standard.removeObject(forKey: dismissedMatchesKey)
            saveLocal()
        }
    }

    // MARK: - Swiping

    func loadNameQueue() {
        guard nameDatabase.isLoaded else {
            print("loadNameQueue: Database not loaded yet")
            return
        }

        // Prioritize ALL partner-liked names that user hasn't swiped yet (bypass filters)
        let unswipedPartnerLikes = partnerLikedIds.subtracting(swipedNameIds)
        let partnerLikedNames = nameDatabase.names(for: Array(unswipedPartnerLikes))
            .shuffled()

        // Fill remainder with random names (minimum 10 total)
        let minQueueSize = 10
        let remainingCount = max(0, minQueueSize - partnerLikedNames.count)
        let partnerLikedIdsSet = Set(partnerLikedNames.map { $0.id })
        let randomNames = nameDatabase.randomNames(
            count: remainingCount,
            with: filters,
            excluding: swipedNameIds.union(partnerLikedIdsSet)
        )

        // Partner-liked names first, then random
        currentNameQueue = partnerLikedNames + randomNames
        print("loadNameQueue: Got \(currentNameQueue.count) names (\(partnerLikedNames.count) partner-liked, \(randomNames.count) random), first: \(currentNameQueue.first?.name ?? "none")")
    }

    func swipe(name: BabyName, liked: Bool) {
        let swipe = Swipe(
            nameId: name.id,
            liked: liked,
            userId: userId
        )

        // Add to undo history
        let historyItem = SwipeHistoryItem(swipe: swipe, name: name)
        undoHistory.insert(historyItem, at: 0)
        if undoHistory.count > maxUndoCount {
            undoHistory.removeLast()
        }

        // Record swipe
        swipes.append(swipe)
        statistics.recordSwipe(liked: liked)

        // Check for match if liked
        if liked {
            checkForMatch(nameId: name.id)
        }

        // Remove from queue
        currentNameQueue.removeAll { $0.id == name.id }

        // Reload queue if running low
        if currentNameQueue.count < 3 {
            loadNameQueue()
        }

        saveLocal()

        // Sync swipe to CloudKit
        if let householdCode = household?.code {
            Task {
                do {
                    try await cloudSync.saveSwipe(swipe, householdCode: householdCode)
                } catch {
                    print("Failed to sync swipe to CloudKit: \(error)")
                }
            }
        }
    }

    func undo() {
        guard let lastSwipe = undoHistory.first else { return }

        // Remove from undo history
        undoHistory.removeFirst()

        // Remove the swipe
        swipes.removeAll { $0.id == lastSwipe.swipe.id }

        // Update statistics
        statistics.undoSwipe(liked: lastSwipe.swipe.liked)

        // If it was liked, check if we need to remove a match
        if lastSwipe.swipe.liked {
            matches.removeAll { $0.nameId == lastSwipe.swipe.nameId }
        }

        // Add the name back to the front of the queue
        currentNameQueue.insert(lastSwipe.name, at: 0)

        saveLocal()
    }

    // MARK: - Match Detection

    private func checkForMatch(nameId: String) {
        // Check if partner also liked this name
        if partnerLikedIds.contains(nameId) {
            createMatch(nameId: nameId)
        }
    }

    private func createMatch(nameId: String) {
        // Don't create duplicate matches or recreate dismissed ones
        guard !matchedNameIds.contains(nameId) else { return }
        guard !dismissedMatchIds.contains(nameId) else { return }

        let match = Match(nameId: nameId)
        matches.append(match)
        statistics.recordMatch()

        // Show celebration
        if let name = nameDatabase.name(for: nameId) {
            lastMatchedName = name
            showMatchCelebration = true
        }

        saveLocal()
    }

    func dismissMatchCelebration() {
        showMatchCelebration = false
        lastMatchedName = nil
    }

    // MARK: - Filters

    func updateFilters(_ newFilters: NameFilters) {
        print("updateFilters called - firstLetters: \(newFilters.firstLetters)")
        filters = newFilters
        // Force clear and reload
        currentNameQueue = []
        loadNameQueue()
        saveLocal()
        print("Queue reloaded with \(currentNameQueue.count) names")
    }

    func resetFilters() {
        filters = .default
        loadNameQueue()
        saveLocal()
    }

    // MARK: - Matches Management

    func removeMatch(_ match: Match) {
        matches.removeAll { $0.id == match.id }
        dismissedMatchIds.insert(match.nameId)
        saveLocal()

        // Sync dismissal to CloudKit (so partner sees it was dismissed)
        if let householdCode = household?.code {
            Task {
                try? await cloudSync.saveDismissedMatch(nameId: match.nameId, userId: userId, householdCode: householdCode)
                try? await cloudSync.deleteMatch(nameId: match.nameId, householdCode: householdCode)
            }
        }
    }

    func removeMatch(nameId: String) {
        matches.removeAll { $0.nameId == nameId }
        dismissedMatchIds.insert(nameId)
        saveLocal()

        // Sync dismissal to CloudKit (so partner sees it was dismissed)
        if let householdCode = household?.code {
            Task {
                try? await cloudSync.saveDismissedMatch(nameId: nameId, userId: userId, householdCode: householdCode)
                try? await cloudSync.deleteMatch(nameId: nameId, householdCode: householdCode)
            }
        }
    }

    func updateMatchRating(nameId: String, rating: Int?) {
        if let index = matches.firstIndex(where: { $0.nameId == nameId }) {
            matches[index].rating = rating
            saveLocal()
        }
    }

    func updateMatchNotes(nameId: String, notes: String?) {
        if let index = matches.firstIndex(where: { $0.nameId == nameId }) {
            matches[index].notes = notes?.isEmpty == true ? nil : notes
            saveLocal()
        }
    }

    func match(for nameId: String) -> Match? {
        matches.first { $0.nameId == nameId }
    }

    // MARK: - Persistence

    private func loadLocalData() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Load swipes
        if let data = UserDefaults.standard.data(forKey: swipesKey),
           let decoded = try? decoder.decode([Swipe].self, from: data) {
            swipes = decoded
        }

        // Load matches
        if let data = UserDefaults.standard.data(forKey: matchesKey),
           let decoded = try? decoder.decode([Match].self, from: data) {
            matches = decoded
        }

        // Load filters
        if let data = UserDefaults.standard.data(forKey: filtersKey),
           let decoded = try? decoder.decode(NameFilters.self, from: data) {
            filters = decoded
        }

        // Load household
        if let data = UserDefaults.standard.data(forKey: householdKey),
           let decoded = try? decoder.decode(Household.self, from: data) {
            household = decoded
            print("Loaded household from UserDefaults: \(decoded.code)")
        }

        // Load statistics
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let decoded = try? decoder.decode(Statistics.self, from: data) {
            statistics = decoded
        }

        // Load dismissed matches
        if let data = UserDefaults.standard.data(forKey: dismissedMatchesKey),
           let decoded = try? decoder.decode(Set<String>.self, from: data) {
            dismissedMatchIds = decoded
        }

        // Initial queue load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadNameQueue()

            // Auto-sync if we have a household
            if self?.household != nil {
                Task {
                    await self?.syncWithCloud()
                }
                self?.startAutoSync()
            }
        }
    }

    private func saveLocal() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(swipes) {
            UserDefaults.standard.set(data, forKey: swipesKey)
        }

        if let data = try? encoder.encode(matches) {
            UserDefaults.standard.set(data, forKey: matchesKey)
        }

        if let data = try? encoder.encode(filters) {
            UserDefaults.standard.set(data, forKey: filtersKey)
        }

        if let data = try? encoder.encode(household) {
            UserDefaults.standard.set(data, forKey: householdKey)
        }

        if let data = try? encoder.encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }

        if let data = try? encoder.encode(dismissedMatchIds) {
            UserDefaults.standard.set(data, forKey: dismissedMatchesKey)
        }
    }

    // MARK: - Reset

    func resetAllData() {
        // Sync deletions to CloudKit before clearing local data
        // This must complete before we clear to avoid phantom data
        if let householdCode = household?.code {
            Task { @MainActor in
                // Mark all matches as dismissed so partner sees them disappear
                for match in matches {
                    do {
                        try await cloudSync.saveDismissedMatch(nameId: match.nameId, userId: userId, householdCode: householdCode)
                        try await cloudSync.deleteMatch(nameId: match.nameId, householdCode: householdCode)
                    } catch {
                        print("resetAllData: Failed to sync match deletion: \(error)")
                    }
                }

                // Delete YOUR swipe records from CloudKit to prevent phantom partner swipes
                do {
                    try await cloudSync.deleteAllUserData(userId: userId, householdCode: householdCode)
                    print("resetAllData: Deleted CloudKit records for user \(userId)")
                } catch {
                    print("resetAllData: Failed to delete CloudKit records: \(error)")
                }

                // Now clear local data after CloudKit cleanup
                await MainActor.run {
                    // Remember dismissed matches so they don't reappear on sync
                    let matchIdsToKeepDismissed = Set(matches.map { $0.nameId })
                    dismissedMatchIds.formUnion(matchIdsToKeepDismissed)

                    // Clear all in-memory state (except household and dismissedMatchIds)
                    swipes = []
                    matches = []
                    filters = .default
                    statistics = Statistics()
                    undoHistory = []
                    currentNameQueue = []
                    partnerDismissedMatchIds = []
                    lastMatchedName = nil
                    showMatchCelebration = false

                    // Clear persisted data (except household and dismissedMatches)
                    UserDefaults.standard.removeObject(forKey: swipesKey)
                    UserDefaults.standard.removeObject(forKey: matchesKey)
                    UserDefaults.standard.removeObject(forKey: filtersKey)
                    UserDefaults.standard.removeObject(forKey: statisticsKey)

                    // Save updated dismissedMatchIds so matches don't reappear
                    saveLocal()

                    // Reload fresh name queue
                    loadNameQueue()

                    // Trigger immediate sync to update partner
                    Task {
                        await syncWithCloud()
                    }
                }
            }
        } else {
            // No household - just clear local data immediately
            // Remember dismissed matches for consistency
            let matchIdsToKeepDismissed = Set(matches.map { $0.nameId })
            dismissedMatchIds.formUnion(matchIdsToKeepDismissed)

            swipes = []
            matches = []
            filters = .default
            statistics = Statistics()
            undoHistory = []
            currentNameQueue = []
            partnerDismissedMatchIds = []
            lastMatchedName = nil
            showMatchCelebration = false

            UserDefaults.standard.removeObject(forKey: swipesKey)
            UserDefaults.standard.removeObject(forKey: matchesKey)
            UserDefaults.standard.removeObject(forKey: filtersKey)
            UserDefaults.standard.removeObject(forKey: statisticsKey)

            saveLocal()
            loadNameQueue()
        }
    }

    // MARK: - CloudKit Integration

    @Published var isSyncing = false
    @Published var lastSyncError: String?
    private var syncTimer: Timer?

    func startAutoSync() {
        stopAutoSync()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncWithCloud()
            }
        }
        print("Auto-sync started (every 5 seconds)")
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    func syncWithCloud() async {
        guard let householdCode = household?.code else {
            print("syncWithCloud: No household to sync")
            // Clear partner swipes if no household
            partnerSwipes = []
            statistics.partnerSwipes = 0
            return
        }

        // Avoid overlapping syncs
        guard !isSyncing else { return }

        isSyncing = true
        lastSyncError = nil

        do {
            // Fetch updated member list
            let members = try await cloudSync.fetchMembers(householdCode: householdCode)
            if members.count != household?.memberIds.count {
                household?.memberIds = members
                print("syncWithCloud: Updated members to \(members.count)")
            }

            let (fetchedPartnerSwipes, fetchedMatches) = try await cloudSync.performFullSync(
                householdCode: householdCode,
                userId: userId,
                localSwipes: swipes,
                localMatches: matches
            )

            // Update partner swipes
            let previousPartnerLikedIds = partnerLikedIds
            partnerSwipes = fetchedPartnerSwipes
            statistics.partnerSwipes = fetchedPartnerSwipes.count

            // Boost newly partner-liked names after current card (bypass filters)
            let newPartnerLikedIds = partnerLikedIds.subtracting(previousPartnerLikedIds).subtracting(swipedNameIds)
            if !newPartnerLikedIds.isEmpty {
                let currentQueueIds = Set(currentNameQueue.map { $0.id })
                let namesToBoost = nameDatabase.names(for: Array(newPartnerLikedIds))
                    .filter { !currentQueueIds.contains($0.id) }
                if !namesToBoost.isEmpty {
                    // Insert at position 1 so current card isn't replaced (or 0 if queue empty)
                    let insertIndex = min(1, currentNameQueue.count)
                    currentNameQueue.insert(contentsOf: namesToBoost, at: insertIndex)
                    print("syncWithCloud: Boosted \(namesToBoost.count) partner-liked names to position \(insertIndex)")
                }
            }

            // Fetch partner's dismissed matches (before checking for new matches)
            let partnerDismissed = try await cloudSync.fetchPartnerDismissedMatches(
                householdCode: householdCode,
                excludingUserId: userId
            )
            partnerDismissedMatchIds = partnerDismissed

            // Check for new matches from partner's swipes (excluding dismissed by either partner)
            for partnerSwipe in fetchedPartnerSwipes where partnerSwipe.liked {
                if likedNameIds.contains(partnerSwipe.nameId) &&
                   !matchedNameIds.contains(partnerSwipe.nameId) &&
                   !dismissedMatchIds.contains(partnerSwipe.nameId) &&
                   !partnerDismissed.contains(partnerSwipe.nameId) {
                    createMatch(nameId: partnerSwipe.nameId)
                }
            }

            // Remove local matches that were deleted remotely (but keep partner-dismissed ones to show indicator)
            let remoteMatchIds = Set(fetchedMatches.map { $0.nameId })
            matches.removeAll { match in
                !remoteMatchIds.contains(match.nameId) && !partnerDismissed.contains(match.nameId)
            }

            // Add new remote matches (excluding dismissed ones)
            for remoteMatch in fetchedMatches {
                if !matchedNameIds.contains(remoteMatch.nameId) && !dismissedMatchIds.contains(remoteMatch.nameId) && !partnerDismissed.contains(remoteMatch.nameId) {
                    matches.append(remoteMatch)
                }
            }

            saveLocal()
            print("syncWithCloud: Synced successfully. Partner swipes: \(fetchedPartnerSwipes.count), Matches: \(fetchedMatches.count), Partner dismissed: \(partnerDismissed.count)")

        } catch {
            lastSyncError = error.localizedDescription
            print("syncWithCloud: Error - \(error)")
        }

        isSyncing = false
    }

    func updatePartnerSwipes(_ swipes: [Swipe]) {
        partnerSwipes = swipes
        statistics.partnerSwipes = swipes.count

        // Check for any new matches (excluding dismissed)
        for swipe in swipes where swipe.liked {
            if likedNameIds.contains(swipe.nameId) && !matchedNameIds.contains(swipe.nameId) && !dismissedMatchIds.contains(swipe.nameId) {
                createMatch(nameId: swipe.nameId)
            }
        }
    }
}
