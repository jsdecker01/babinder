# NameMatch - Baby Name Swiper App

## Overview
A Tinder-style app for couples to discover baby names together. Swipe right on names you like, and when both partners match on a name, it's saved to your shared list.

---

## Core Features

### 1. Swipe Interface
- Card stack UI with drag gesture
- Swipe right = like, swipe left = pass
- Visual feedback (green/red overlay, rotation)
- Undo last swipe option
- Progress indicator showing names remaining

### 2. Household Pairing
- Generate a unique 6-character code on first launch
- Partner enters the code to join household
- Both see same pool of names (synced via CloudKit)
- Support for re-pairing if needed

### 3. Match System
- When both partners swipe right → Match!
- Celebration animation on match
- Matches saved to shared "Favorites" list
- Can view all matches anytime

### 4. Filtering
- **Gender**: Male, Female, Gender Neutral
- **Origin**: English, Hebrew, Spanish, Irish, Greek, etc.
- **Style**: Classic, Modern, Unique, Biblical, Nature, etc.
- **First Letter**: A-Z filter
- **Popularity**: Popular, Uncommon, Rare

### 5. Name Database
- Bundled JSON with 5,000+ names
- Each name has: name, gender, origins[], styles[], meaning, popularity

---

## Data Models

```swift
// Name from database
struct BabyName: Codable, Identifiable {
    let id: String  // The name itself as ID
    let name: String
    let gender: Gender
    let origins: [Origin]
    let styles: [Style]
    let meaning: String?
    let popularity: Popularity
}

enum Gender: String, Codable, CaseIterable {
    case male, female, neutral
}

enum Origin: String, Codable, CaseIterable {
    case english, hebrew, greek, latin, irish, spanish,
         german, french, arabic, indian, japanese, african
}

enum Style: String, Codable, CaseIterable {
    case classic, modern, unique, biblical, nature,
         literary, royal, mythological
}

enum Popularity: String, Codable, CaseIterable {
    case popular, common, uncommon, rare
}

// User's swipe on a name
struct Swipe: Codable, Identifiable {
    let id: UUID
    let nameid: String
    let odirikedIt: Bool
    let userId: String
    let timestamp: Date
}

// A matched name (both liked)
struct Match: Codable, Identifiable {
    let id: UUID
    let nameId: String
    let matchedAt: Date
}

// Household for syncing
struct Household: Codable {
    let id: UUID
    let code: String  // 6-char join code
    let memberIds: [String]
    let createdAt: Date
}

// Filter preferences
struct NameFilters: Codable {
    var genders: Set<Gender>
    var origins: Set<Origin>
    var styles: Set<Style>
    var firstLetters: Set<Character>
    var popularities: Set<Popularity>
}
```

---

## CloudKit Schema

### Record Types (create in CloudKit Console)

1. **Household**
   - `code` (String) - 6-char unique code
   - `memberIds` (String List) - device/user IDs
   - `createdAt` (Date)

2. **Swipe**
   - `householdId` (Reference → Household)
   - `nameId` (String)
   - `likedIt` (Int64) - 1 = liked, 0 = passed
   - `userId` (String)
   - `timestamp` (Date)

3. **Match**
   - `householdId` (Reference → Household)
   - `nameId` (String)
   - `matchedAt` (Date)

4. **Filters**
   - `householdId` (Reference → Household)
   - `filtersData` (Bytes) - JSON encoded filters

---

## App Architecture

```
NameMatch/
├── App.swift                    # Entry point
├── Models/
│   ├── BabyName.swift          # Name model + enums
│   ├── Swipe.swift             # Swipe record
│   ├── Match.swift             # Match record
│   ├── Household.swift         # Household model
│   └── NameFilters.swift       # Filter preferences
├── Services/
│   ├── NameDatabase.swift      # Load/filter names from JSON
│   ├── CloudSyncService.swift  # CloudKit operations
│   └── HouseholdService.swift  # Pairing logic
├── Stores/
│   └── AppStore.swift          # Main state management
├── Views/
│   ├── MainTabView.swift       # Tab container
│   ├── Swipe/
│   │   ├── SwipeView.swift     # Main swipe screen
│   │   ├── NameCard.swift      # Individual card
│   │   └── CardStack.swift     # Stacked cards with gestures
│   ├── Matches/
│   │   └── MatchesView.swift   # List of matched names
│   ├── Filters/
│   │   └── FiltersView.swift   # Filter selection
│   ├── Settings/
│   │   ├── SettingsView.swift  # Settings screen
│   │   └── HouseholdView.swift # Pairing UI
│   └── Onboarding/
│       └── OnboardingView.swift # First launch flow
└── Resources/
    └── names.json              # Name database
```

---

## Screen Flow

```
Launch
   │
   ▼
┌─────────────────┐
│   Onboarding    │ (first launch only)
│  - Create/Join  │
│    Household    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Main Tabs     │
├─────────────────┤
│ [Swipe] [♥] [⚙] │
└────────┬────────┘
         │
    ┌────┴────┬──────────┐
    ▼         ▼          ▼
┌───────┐ ┌───────┐ ┌──────────┐
│ Swipe │ │Matches│ │ Settings │
│ Cards │ │ List  │ │ Filters  │
└───────┘ └───────┘ │ Household│
                    └──────────┘
```

---

## Implementation Order

### Phase 1: Core Structure
1. Create Xcode project with CloudKit capability
2. Define all data models
3. Create name database JSON (subset of ~500 names to start)
4. Build NameDatabase service to load/filter names

### Phase 2: Swipe UI
5. Build NameCard component
6. Build CardStack with drag gestures
7. Build SwipeView with like/pass buttons
8. Add swipe animations and visual feedback

### Phase 3: Local State
9. Build AppStore for state management
10. Track swipes locally (UserDefaults)
11. Filter names by swipe status
12. Build basic MatchesView

### Phase 4: Household & Sync
13. Build HouseholdService (code generation, joining)
14. Build CloudSyncService
15. Sync swipes between partners
16. Detect and sync matches

### Phase 5: Filters & Polish
17. Build FiltersView
18. Apply filters to name queue
19. Build SettingsView
20. Add onboarding flow
21. Match celebration animation
22. Haptic feedback throughout

---

## Key Technical Decisions

### Swipe Gesture Implementation
```swift
// Card uses DragGesture with threshold
.gesture(
    DragGesture()
        .onChanged { value in
            offset = value.translation
            // Rotate based on horizontal drag
        }
        .onEnded { value in
            if value.translation.width > 100 {
                // Swipe right - LIKE
            } else if value.translation.width < -100 {
                // Swipe left - PASS
            } else {
                // Snap back
            }
        }
)
```

### Match Detection
When user swipes right:
1. Save swipe to CloudKit
2. Query: "Did partner also swipe right on this name?"
3. If yes → Create Match record, trigger celebration

### Household Pairing
- Use device UUID as userId (stored in Keychain for persistence)
- Generate 6-char alphanumeric code (no ambiguous chars like 0/O, 1/l)
- Code stored in CloudKit, lookup by code to join

### Name Queue Management
- Load all names matching current filters
- Exclude names already swiped by this user
- Shuffle for variety
- Preload next 3-5 cards for smooth UX

---

## Decisions Made

1. **Name source**: Generate modular JSON database, easy to swap/extend
2. **Household size**: Couples only (2 people)
3. **CloudKit**: Public database for simplicity
4. **Undo**: Allow undoing last 5 swipes
5. **Statistics**: Yes - show swipe count, match count, partner progress
6. **App name**: NameMatch (subject to change)

---

## Implementation Phases

### Phase 1: Project Setup & Models
- [ ] Create Xcode project with CloudKit
- [ ] Define all data models
- [ ] Create name database JSON (~2000 names)
- [ ] Build NameDatabase service

### Phase 2: Swipe UI
- [ ] Build NameCard component
- [ ] Build CardStack with drag gestures
- [ ] Build SwipeView with buttons
- [ ] Add animations and haptics

### Phase 3: Local State & Matches
- [ ] Build AppStore
- [ ] Track swipes locally
- [ ] Build MatchesView
- [ ] Add undo functionality (5 max)

### Phase 4: CloudKit Sync
- [ ] Build HouseholdService
- [ ] Build CloudSyncService
- [ ] Sync swipes between partners
- [ ] Match detection

### Phase 5: Filters & Polish
- [ ] Build FiltersView
- [ ] Build SettingsView with stats
- [ ] Onboarding flow
- [ ] Match celebration animation
