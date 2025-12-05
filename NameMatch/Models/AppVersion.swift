import Foundation

struct AppVersion {
    static let appName = "Babinder"

    let version: String
    let build: String
    let releaseNotes: String
    let releaseDate: Date

    static let current = AppVersion(
        version: "1.2.0",
        build: "3",
        releaseNotes: """
        Partner Queue Boost

        • Names your partner likes now appear at the top of your queue
        • Partner-liked names bypass filters so you never miss what they loved
        • Real-time boosting during sync (without interrupting your current card)
        • No limit — all partner likes get priority
        """,
        releaseDate: Date()
    )

    static let history: [AppVersion] = [
        current,
        AppVersion(
            version: "1.1.0",
            build: "2",
            releaseNotes: """
            Enhanced Swiping & Data

            • Curved swipe path animation for smoother card movement
            • Expanded name database with thousands more options
            • Clearer statistics with helpful explanations
            • Improved data reset functionality
            • Added data source transparency
            """,
            releaseDate: Date()
        ),
        AppVersion(
            version: "1.0.0",
            build: "1",
            releaseNotes: """
            Initial Release

            • Swipe through baby names Tinder-style
            • Match with your partner on favorite names
            • Filter by gender, origin, style, and more
            • Sync across devices with CloudKit
            """,
            releaseDate: Date()
        )
    ]
}
