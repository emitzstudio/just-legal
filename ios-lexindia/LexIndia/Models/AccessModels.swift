//
//  AccessModels.swift
//  LexIndia
//
//  Account, entitlement and subscription models. Shaped so the mock local
//  flow can later be replaced by a production backend without UI changes.
//

import Foundation

/// A locally stored account (preview authentication — no backend yet).
nonisolated struct AuthUser: Codable, Equatable {
    var name: String
    var email: String
    var joinedAt: Date
}

/// What currently unlocks the app.
nonisolated enum Entitlement: Codable, Equatable {
    case none
    /// 24-hour full-access trial.
    case trial(start: Date, end: Date)
    /// A paid plan from `PlanCatalog`.
    case subscription(planId: String, start: Date, end: Date)
    /// DEVELOPMENT ONLY — permanent test access, gated by `DevConfig`.
    case devUnlimited

    func isActive(at date: Date) -> Bool {
        switch self {
        case .none:
            return false
        case .trial(_, let end):
            return date < end
        case .subscription(_, _, let end):
            return date < end
        case .devUnlimited:
            return DevConfig.permanentTestAccessEnabled
        }
    }
}

/// One purchasable plan. Duration, price and the included Ask-credit
/// allowance all live here — never hard-coded in UI components.
nonisolated struct SubscriptionPlan: Identifiable, Hashable {
    let id: String
    let months: Int
    /// Exact price in rupees.
    let priceINR: Int
    /// MOCK allowance for now — final amounts will be configured here later.
    let includedCredits: Int
    let isRecommended: Bool

    var durationLabel: String { months == 1 ? "1 month" : "\(months) months" }
    var priceLabel: String { "₹\(priceINR)" }

    /// Approximate effective monthly price.
    var perMonthLabel: String {
        let perMonth = Int((Double(priceINR) / Double(months)).rounded())
        return "≈ ₹\(perMonth)/month"
    }

    /// Rupees saved against paying month-by-month, if any.
    var savingsINR: Int? {
        let baseline = months * PlanCatalog.monthlyBaselineINR
        let saved = baseline - priceINR
        return saved > 0 ? saved : nil
    }
}

/// The five production plans, in display order. Do not invent others.
nonisolated enum PlanCatalog {
    /// The 1-month price, used as the savings baseline.
    static let monthlyBaselineINR = 128

    static let plans: [SubscriptionPlan] = [
        SubscriptionPlan(id: "plan-12m", months: 12, priceINR: 588, includedCredits: 480, isRecommended: true),
        SubscriptionPlan(id: "plan-9m", months: 9, priceINR: 428, includedCredits: 320, isRecommended: false),
        SubscriptionPlan(id: "plan-6m", months: 6, priceINR: 328, includedCredits: 200, isRecommended: false),
        SubscriptionPlan(id: "plan-3m", months: 3, priceINR: 228, includedCredits: 90, isRecommended: false),
        SubscriptionPlan(id: "plan-1m", months: 1, priceINR: 128, includedCredits: 30, isRecommended: false)
    ]

    static func plan(_ id: String) -> SubscriptionPlan? {
        plans.first { $0.id == id }
    }
}

/// One scheduled trial reminder. Each is shown at most once.
nonisolated struct TrialReminder: Identifiable, Equatable {
    let id: String
    let offsetMinutes: Int
    let title: String
}

/// The fixed reminder schedule for the 24-hour trial.
nonisolated enum TrialReminderSchedule {
    static let all: [TrialReminder] = [
        TrialReminder(id: "r-12h", offsetMinutes: 720, title: "Halfway through your free day"),
        TrialReminder(id: "r-18h", offsetMinutes: 1080, title: "6 hours left in your trial"),
        TrialReminder(id: "r-20h", offsetMinutes: 1200, title: "4 hours left in your trial"),
        TrialReminder(id: "r-22h", offsetMinutes: 1320, title: "2 hours left in your trial"),
        TrialReminder(id: "r-23h", offsetMinutes: 1380, title: "1 hour left in your trial"),
        TrialReminder(id: "r-23h30", offsetMinutes: 1410, title: "30 minutes left in your trial"),
        TrialReminder(id: "r-23h45", offsetMinutes: 1425, title: "15 minutes left in your trial"),
        TrialReminder(id: "r-23h55", offsetMinutes: 1435, title: "5 minutes left in your trial"),
        TrialReminder(id: "r-23h58", offsetMinutes: 1438, title: "Your trial is about to end")
    ]
}
