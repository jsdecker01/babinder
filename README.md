# NameMatch

A Tinder-style iOS app for couples to discover baby names together. Swipe right on names you like, and when both partners match on the same name, it's saved to your shared favorites list.

## Features

- **Swipe Interface**: Tinder-style cards with drag gestures, visual feedback, and haptic responses
- **Partner Matching**: When both partners swipe right on the same name, it's a match!
- **Smart Filters**: Filter by gender, origin, style, popularity, and first letter
- **CloudKit Sync**: Sync swipes and matches between partners in real-time
- **Undo Support**: Undo your last 5 accidental swipes
- **Statistics**: Track your swipe count, match rate, and partner progress

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode and create a new iOS App project
2. Name it `NameMatch`
3. Select SwiftUI for the interface
4. Enable CloudKit capability

### 2. Add Source Files

Copy the contents of the `NameMatch/` folder into your Xcode project:

```
NameMatch/
├── NameMatchApp.swift
├── Models/
│   ├── BabyName.swift
│   ├── Swipe.swift
│   ├── Match.swift
│   ├── Household.swift
│   ├── NameFilters.swift
│   ├── Statistics.swift
│   └── AppVersion.swift
├── Services/
│   ├── NameDatabase.swift
│   ├── CloudSyncService.swift
│   └── HouseholdService.swift
├── Stores/
│   └── AppStore.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Swipe/
│   │   ├── SwipeView.swift
│   │   ├── NameCard.swift
│   │   └── CardStack.swift
│   ├── Matches/
│   │   └── MatchesView.swift
│   ├── Filters/
│   │   └── FiltersView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── HouseholdView.swift
│   └── Onboarding/
│       └── OnboardingView.swift
└── Resources/
    └── names.json
```

### 3. Configure CloudKit

1. In Xcode, go to your target's Signing & Capabilities
2. Add the CloudKit capability
3. Create a new container: `iCloud.com.yourcompany.NameMatch`
4. Update the container identifier in `CloudSyncService.swift`

### 4. CloudKit Console Setup

Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard) and create these record types:

#### Household
| Field | Type |
|-------|------|
| code | String |
| memberIds | String List |
| createdAt | Date/Time |

#### Swipe
| Field | Type |
|-------|------|
| householdCode | String |
| nameId | String |
| liked | Int64 |
| userId | String |
| timestamp | Date/Time |

#### Match
| Field | Type |
|-------|------|
| householdCode | String |
| nameId | String |
| matchedAt | Date/Time |

**Important**: After creating each record type, go to Security Roles and grant Read/Write permissions to authenticated users.

### 5. Add names.json to Bundle

Make sure `names.json` is added to your Xcode project and included in "Copy Bundle Resources" build phase.

### 6. Build and Run

Build and run on a simulator or device. The app works offline-first, so CloudKit sync failures won't break the local experience.

## Architecture

```
Views → Stores → Services
         ↓
       Models
```

- **Views**: Pure SwiftUI, no business logic
- **Stores**: `@MainActor` ObservableObjects with `@Published` properties
- **Services**: Singletons for CloudKit and data operations
- **Models**: Codable structs with computed properties

## Name Database

The app includes ~350 names across:
- **Genders**: Male, Female, Gender Neutral
- **Origins**: English, Hebrew, Greek, Latin, Irish, Spanish, German, French, Arabic, Indian, Japanese, African, Scottish, Italian, Scandinavian, Slavic, Welsh, Persian, Chinese, Korean
- **Styles**: Classic, Modern, Unique, Biblical, Nature, Literary, Royal, Mythological, Vintage, Trendy, Strong, Gentle, Artistic, Scientific
- **Popularity**: Popular, Common, Uncommon, Rare

To add more names, edit `names.json` following the existing format.

## Version History

### v1.2.0
**Partner Queue Boost**
- Names your partner likes now appear at the top of your queue
- Partner-liked names bypass your filter settings so you never miss what they loved
- Real-time boosting: new partner likes insert after your current card during sync
- No limit on boosted names - all partner likes get priority

### v1.1.0
**Matches & UI Polish**
- Match detail view with rating (1-5 hearts) and notes
- Partner can see when you've removed a match
- Improved card animations and haptic feedback
- Bug fixes for CloudKit sync reliability

### v1.0.0
**Initial Release**
- Swipe interface with drag gestures and visual feedback
- Partner matching via shareable household codes
- Smart filters: gender, origin, style, popularity, first letter
- CloudKit sync for real-time partner updates
- Statistics tracking (swipes, matches, partner progress)
- Undo support for last 5 swipes

## License

MIT
