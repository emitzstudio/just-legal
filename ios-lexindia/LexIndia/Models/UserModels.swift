//
//  UserModels.swift
//  LexIndia
//
//  Locally persisted user data. Shaped so it can later connect to a backend
//  without changing the UI.
//

import Foundation

nonisolated struct CreditTransaction: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let delta: Int
    let reason: String
}

nonisolated struct SavedItem: Codable, Identifiable, Hashable {
    let sectionId: String
    var note: String
    let savedAt: Date
    var editedAt: Date?

    var id: String { sectionId }
}

nonisolated struct RecentItem: Codable, Identifiable, Hashable {
    let sectionId: String
    let date: Date

    var id: String { sectionId }
}

/// A document the user downloaded to this device (generated PDF).
nonisolated struct DownloadRecord: Codable, Identifiable, Hashable {
    let documentId: String
    let fileName: String
    let date: Date

    var id: String { documentId }
}

/// Legacy Ask-thread entry — kept only so old snapshots decode cleanly.
nonisolated struct AskRecord: Codable, Identifiable, Hashable {
    let id: UUID
    /// "user" or "answer".
    let role: String
    let text: String
    let lead: String?
    let example: String?
    let mappingNote: String?
    let sectionIds: [String]
    let definitionIds: [String]
    let noCharge: Bool
    let date: Date
}

/// One entry in the E-Vakeel conversation — the user's question or the
/// assistant's grounded reply. Shaped so a real AI provider can fill the
/// same fields later without UI changes.
nonisolated struct EVakeelRecord: Codable, Identifiable, Hashable {
    let id: UUID
    /// "user" or "assistant".
    let role: String
    let text: String
    let lead: String?
    let mappingNote: String?
    let sectionIds: [String]
    /// Credits actually charged for this reply (0 for user rows and unmatched answers).
    let cost: Int
    /// Consult-a-real-advocate advisory, when the matter sounds serious.
    let advisory: String?
    let date: Date
}

nonisolated struct UserSnapshot: Codable {
    var profileName: String
    var credits: Int
    var creditHistory: [CreditTransaction]
    var isSubscribed: Bool
    var planName: String?
    var subscribedAt: Date?
    var saved: [SavedItem]
    var recents: [RecentItem]
    var recentSearches: [String]
    var askRecords: [AskRecord]?
    var savedDefinitionIds: [String]
    /// Optional so snapshots written before these features decode cleanly.
    var downloads: [DownloadRecord]?
    var language: String?
    var themeMode: String?
    var evakeelRecords: [EVakeelRecord]?
    /// ISO week id ("2026-W34") when the weekly quiz reward was last claimed.
    var quizWeeklyClaimWeek: String?
    var quizzesPlayed: Int?
    /// Consecutive 100% quiz scores toward the weekly reward.
    var quizPerfectStreak: Int?
    /// Persisted position of the floating E-Vakeel button.
    var evakeelDockOnRight: Bool?
    var evakeelDockY: Double?
}
