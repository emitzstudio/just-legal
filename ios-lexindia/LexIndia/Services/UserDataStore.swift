//
//  UserDataStore.swift
//  LexIndia
//
//  Locally persisted user state: profile, credits, subscription, saved
//  sections and notes, recents, search history, downloads, the E-Vakeel
//  conversation, quiz rewards and interface preferences.
//

import Foundation
import Observation

@Observable
final class UserDataStore {
    private static let storageKey = "lexindia.user.v1"
    private static let welcomeCredits = 24

    private(set) var profileName: String = "Arjun"
    private(set) var credits: Int = UserDataStore.welcomeCredits
    private(set) var creditHistory: [CreditTransaction] = []
    private(set) var isSubscribed: Bool = false
    private(set) var planName: String?
    private(set) var subscribedAt: Date?
    private(set) var saved: [SavedItem] = []
    private(set) var recents: [RecentItem] = []
    private(set) var recentSearches: [String] = []
    private(set) var savedDefinitionIds: [String] = []
    private(set) var downloads: [DownloadRecord] = []
    private(set) var language: AppLanguage = .english
    private(set) var themeMode: ThemeMode = .system
    private(set) var evakeelRecords: [EVakeelRecord] = []
    private(set) var quizWeeklyClaimWeek: String?
    private(set) var quizzesPlayed: Int = 0
    private(set) var quizPerfectStreak: Int = 0
    private(set) var evakeelDockOnRight: Bool = true
    private(set) var evakeelDockY: Double = 0.58

    init() {
        load()
    }

    // MARK: - Profile

    func setName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profileName = String(trimmed.prefix(24))
        save()
    }

    // MARK: - Saved sections & notes

    func isSaved(_ sectionId: String) -> Bool {
        saved.contains { $0.sectionId == sectionId }
    }

    /// Toggles the bookmark. Returns true when the section is now saved.
    @discardableResult
    func toggleSaved(_ sectionId: String) -> Bool {
        if let index = saved.firstIndex(where: { $0.sectionId == sectionId }) {
            saved.remove(at: index)
            save()
            return false
        }
        saved.insert(SavedItem(sectionId: sectionId, note: "", savedAt: Date(), editedAt: nil), at: 0)
        save()
        return true
    }

    func savedItem(for sectionId: String) -> SavedItem? {
        saved.first { $0.sectionId == sectionId }
    }

    func updateNote(for sectionId: String, note: String) {
        guard let index = saved.firstIndex(where: { $0.sectionId == sectionId }) else { return }
        saved[index].note = note
        saved[index].editedAt = Date()
        save()
    }

    func removeSaved(_ sectionId: String) {
        saved.removeAll { $0.sectionId == sectionId }
        save()
    }

    // MARK: - Saved definitions

    func isDefinitionSaved(_ id: String) -> Bool {
        savedDefinitionIds.contains(id)
    }

    func toggleSavedDefinition(_ id: String) {
        if let index = savedDefinitionIds.firstIndex(of: id) {
            savedDefinitionIds.remove(at: index)
        } else {
            savedDefinitionIds.insert(id, at: 0)
        }
        save()
    }

    // MARK: - Recents & searches

    func recordVisit(_ sectionId: String) {
        recents.removeAll { $0.sectionId == sectionId }
        recents.insert(RecentItem(sectionId: sectionId, date: Date()), at: 0)
        if recents.count > 20 { recents = Array(recents.prefix(20)) }
        save()
    }

    func clearRecents() {
        recents.removeAll()
        save()
    }

    func recordSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 8 { recentSearches = Array(recentSearches.prefix(8)) }
        save()
    }

    func clearSearches() {
        recentSearches.removeAll()
        save()
    }

    // MARK: - Downloads (generated PDFs on this device)

    func isDownloaded(_ documentId: String) -> Bool {
        downloads.contains { $0.documentId == documentId }
    }

    func downloadRecord(_ documentId: String) -> DownloadRecord? {
        downloads.first { $0.documentId == documentId }
    }

    func recordDownload(_ record: DownloadRecord) {
        downloads.removeAll { $0.documentId == record.documentId }
        downloads.insert(record, at: 0)
        save()
    }

    func removeDownload(_ documentId: String) {
        downloads.removeAll { $0.documentId == documentId }
        save()
    }

    // MARK: - Interface language & appearance

    func setLanguage(_ newLanguage: AppLanguage) {
        language = newLanguage
        save()
    }

    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        save()
    }

    // MARK: - Credits

    var isLowOnCredits: Bool { credits > 0 && credits <= 5 }

    /// Total credits ever spent (from history).
    var creditsUsed: Int {
        creditHistory.filter { $0.delta < 0 }.reduce(0) { $0 - $1.delta }
    }

    /// Total credits ever granted or purchased (from history).
    var creditsAdded: Int {
        creditHistory.filter { $0.delta > 0 }.reduce(0) { $0 + $1.delta }
    }

    /// Spends a variable amount (E-Vakeel questions can cost more than one).
    @discardableResult
    func spendCredits(_ amount: Int, reason: String) -> Bool {
        guard amount > 0, credits >= amount else { return false }
        credits -= amount
        creditHistory.insert(CreditTransaction(id: UUID(), date: Date(), delta: -amount, reason: reason), at: 0)
        save()
        return true
    }

    func addCredits(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        credits += amount
        creditHistory.insert(CreditTransaction(id: UUID(), date: Date(), delta: amount, reason: reason), at: 0)
        save()
    }

    // MARK: - Subscription

    func subscribe(plan: String) {
        isSubscribed = true
        planName = plan
        subscribedAt = Date()
        addCredits(25, reason: "Included with LexIndia Plus")
    }

    func cancelSubscription() {
        isSubscribed = false
        planName = nil
        subscribedAt = nil
        save()
    }

    // MARK: - E-Vakeel conversation

    func appendEVakeel(_ record: EVakeelRecord) {
        evakeelRecords.append(record)
        if evakeelRecords.count > 80 { evakeelRecords = Array(evakeelRecords.suffix(80)) }
        save()
    }

    func clearEVakeel() {
        evakeelRecords.removeAll()
        save()
    }

    /// Persists where the floating E-Vakeel button was docked.
    func setEVakeelDock(onRight: Bool, yFraction: Double) {
        evakeelDockOnRight = onRight
        evakeelDockY = min(max(yFraction, 0.12), 0.74)
        save()
    }

    // MARK: - Weekly quiz reward

    /// ISO week identity, e.g. "2026-W34".
    static func currentWeekId(_ date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    var isWeeklyQuizRewardAvailable: Bool {
        quizWeeklyClaimWeek != Self.currentWeekId()
    }

    /// True once the perfect-score streak has reached its target.
    var isRewardStreakComplete: Bool {
        quizPerfectStreak >= QuizConfig.streakTarget
    }

    /// Records a finished quiz and advances the perfect-score streak.
    /// A completed streak is kept until the reward is claimed, so a later
    /// slip never wipes an already-earned reward.
    func recordQuizFinished(isPerfect: Bool) {
        quizzesPlayed += 1
        if isPerfect {
            quizPerfectStreak = min(quizPerfectStreak + 1, QuizConfig.streakTarget)
        } else if quizPerfectStreak < QuizConfig.streakTarget {
            quizPerfectStreak = 0
        }
        save()
    }

    /// Claims the weekly reward once per ISO week — only after the
    /// perfect-score streak is complete. Claiming starts a fresh streak.
    @discardableResult
    func claimWeeklyQuizReward(credits amount: Int, quizLabel: String) -> Bool {
        guard isWeeklyQuizRewardAvailable, isRewardStreakComplete, amount > 0 else { return false }
        quizWeeklyClaimWeek = Self.currentWeekId()
        quizPerfectStreak = 0
        addCredits(amount, reason: "Weekly quiz reward — \(quizLabel)")
        return true
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(UserSnapshot.self, from: data) else {
            creditHistory = [CreditTransaction(id: UUID(), date: Date(), delta: Self.welcomeCredits, reason: "Welcome credits")]
            return
        }
        profileName = snapshot.profileName
        credits = snapshot.credits
        creditHistory = snapshot.creditHistory
        isSubscribed = snapshot.isSubscribed
        planName = snapshot.planName
        subscribedAt = snapshot.subscribedAt
        saved = snapshot.saved
        recents = snapshot.recents
        recentSearches = snapshot.recentSearches
        savedDefinitionIds = snapshot.savedDefinitionIds
        downloads = snapshot.downloads ?? []
        language = AppLanguage(rawValue: snapshot.language ?? "") ?? .english
        themeMode = ThemeMode(rawValue: snapshot.themeMode ?? "") ?? .system
        evakeelRecords = snapshot.evakeelRecords ?? []
        quizWeeklyClaimWeek = snapshot.quizWeeklyClaimWeek
        quizzesPlayed = snapshot.quizzesPlayed ?? 0
        quizPerfectStreak = snapshot.quizPerfectStreak ?? 0
        evakeelDockOnRight = snapshot.evakeelDockOnRight ?? true
        evakeelDockY = snapshot.evakeelDockY ?? 0.58
    }

    private func save() {
        let snapshot = UserSnapshot(
            profileName: profileName,
            credits: credits,
            creditHistory: creditHistory,
            isSubscribed: isSubscribed,
            planName: planName,
            subscribedAt: subscribedAt,
            saved: saved,
            recents: recents,
            recentSearches: recentSearches,
            askRecords: nil,
            savedDefinitionIds: savedDefinitionIds,
            downloads: downloads,
            language: language.rawValue,
            themeMode: themeMode.rawValue,
            evakeelRecords: evakeelRecords,
            quizWeeklyClaimWeek: quizWeeklyClaimWeek,
            quizzesPlayed: quizzesPlayed,
            quizPerfectStreak: quizPerfectStreak,
            evakeelDockOnRight: evakeelDockOnRight,
            evakeelDockY: evakeelDockY
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
