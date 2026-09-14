//
//  AccessStore.swift
//  LexIndia
//
//  Authentication and entitlement state: account, subscription, the
//  24-hour trial with its reminder schedule, and dev test access.
//  Persisted locally; designed to be swapped for a production backend.
//

import Foundation
import Observation

@Observable
final class AccessStore {
    private static let storageKey = "lexindia.access.v1"

    private(set) var user: AuthUser?
    /// The last account created on this device, so Sign in can find it.
    private(set) var knownAccount: AuthUser?
    private(set) var entitlement: Entitlement = .none
    private(set) var hasUsedTrial: Bool = false
    private(set) var shownReminderIds: Set<String> = []

    /// The reminder currently presented, if any. Transient — not persisted.
    private(set) var activeReminder: TrialReminder?

    /// Clock the UI reads for countdowns; refreshed by `tick()`.
    private(set) var now: Date = Date()

    init() {
        load()
        tick()
    }

    // MARK: - Derived state

    var isAuthenticated: Bool { user != nil }

    var hasAccess: Bool { entitlement.isActive(at: now) }

    /// True when a trial or subscription existed but has run out.
    var accessExpired: Bool {
        switch entitlement {
        case .trial(_, let end): return now >= end
        case .subscription(_, _, let end): return now >= end
        case .none: return false
        case .devUnlimited: return !DevConfig.permanentTestAccessEnabled
        }
    }

    var expiredEntitlementWasTrial: Bool {
        if case .trial = entitlement { return accessExpired }
        return false
    }

    var isOnTrial: Bool {
        if case .trial = entitlement { return hasAccess }
        return false
    }

    var isDevAccess: Bool {
        if case .devUnlimited = entitlement { return hasAccess }
        return false
    }

    /// Seconds left in the trial, when one is running.
    var trialRemaining: TimeInterval? {
        guard case .trial(_, let end) = entitlement else { return nil }
        return max(0, end.timeIntervalSince(now))
    }

    /// Active plan details, when subscribed.
    var subscriptionInfo: (plan: SubscriptionPlan, start: Date, end: Date)? {
        guard case .subscription(let planId, let start, let end) = entitlement,
              let plan = PlanCatalog.plan(planId),
              now < end else { return nil }
        return (plan, start, end)
    }

    // MARK: - Authentication (preview — local only)

    func register(name: String, email: String) {
        let account = AuthUser(
            name: String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24)),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            joinedAt: Date()
        )
        user = account
        knownAccount = account
        save()
    }

    /// Signs into the account previously created on this device.
    /// Returns false when no matching account exists.
    @discardableResult
    func signIn(email: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let account = knownAccount, account.email == normalized else { return false }
        user = account
        save()
        return true
    }

    func signOut() {
        user = nil
        activeReminder = nil
        save()
    }

    // MARK: - Entitlements

    /// Starts the one-time 24-hour full-access trial.
    func startTrial() {
        let start = Date()
        entitlement = .trial(start: start, end: start.addingTimeInterval(24 * 3600))
        hasUsedTrial = true
        shownReminderIds = []
        activeReminder = nil
        now = start
        save()
    }

    func activateSubscription(_ plan: SubscriptionPlan) {
        let start = Date()
        let end = Calendar.current.date(byAdding: .month, value: plan.months, to: start)
            ?? start.addingTimeInterval(TimeInterval(plan.months) * 30 * 24 * 3600)
        entitlement = .subscription(planId: plan.id, start: start, end: end)
        activeReminder = nil
        now = start
        save()
    }

    /// Demo cancellation — access ends immediately in this preview.
    func cancelSubscription() {
        entitlement = .none
        activeReminder = nil
        save()
    }

    /// DEVELOPMENT ONLY — permanent test access, gated by `DevConfig`.
    func activateDevAccess() {
        guard DevConfig.permanentTestAccessEnabled else { return }
        entitlement = .devUnlimited
        activeReminder = nil
        save()
    }

    func endDevAccess() {
        guard case .devUnlimited = entitlement else { return }
        entitlement = .none
        save()
    }

    // MARK: - Clock & reminders

    /// Refreshes the clock, expires entitlements and surfaces the next due
    /// trial reminder. Each scheduled reminder is shown at most once; when
    /// several fall due together (e.g. the app was closed), only the latest
    /// is presented and the rest are marked as shown.
    func tick() {
        now = Date()
        guard case .trial(let start, let end) = entitlement, now < end else {
            if activeReminder != nil { activeReminder = nil }
            return
        }
        guard activeReminder == nil else { return }
        let elapsedMinutes = Int(now.timeIntervalSince(start) / 60)
        let due = TrialReminderSchedule.all.filter {
            $0.offsetMinutes <= elapsedMinutes && !shownReminderIds.contains($0.id)
        }
        guard let latest = due.max(by: { $0.offsetMinutes < $1.offsetMinutes }) else { return }
        for reminder in due {
            shownReminderIds.insert(reminder.id)
        }
        activeReminder = latest
        save()
    }

    func dismissReminder() {
        activeReminder = nil
    }

    // MARK: - Formatting

    /// "21h 34m", "58m" or "under a minute".
    static func remainingLabel(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "under a minute"
    }

    // MARK: - Persistence

    nonisolated private struct AccessSnapshot: Codable {
        var user: AuthUser?
        var knownAccount: AuthUser?
        var entitlement: Entitlement
        var hasUsedTrial: Bool
        var shownReminderIds: [String]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(AccessSnapshot.self, from: data) else { return }
        user = snapshot.user
        knownAccount = snapshot.knownAccount
        entitlement = snapshot.entitlement
        hasUsedTrial = snapshot.hasUsedTrial
        shownReminderIds = Set(snapshot.shownReminderIds)
    }

    private func save() {
        let snapshot = AccessSnapshot(
            user: user,
            knownAccount: knownAccount,
            entitlement: entitlement,
            hasUsedTrial: hasUsedTrial,
            shownReminderIds: Array(shownReminderIds)
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
