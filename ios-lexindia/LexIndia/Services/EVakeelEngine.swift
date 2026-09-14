//
//  EVakeelEngine.swift
//  LexIndia
//
//  E-Vakeel's brain, behind a provider seam. Today a mock provider
//  grounds answers in the bundled legal dataset; later a GPT/Gemini
//  provider implements the same protocol without touching the UI:
//  question → E-Vakeel → provider → reply → user, with credits tracked.
//

import Foundation

/// One assistant reply, provider-agnostic.
nonisolated struct EVakeelReply {
    let lead: String?
    let text: String
    let mappingNote: String?
    let sectionIds: [String]
    let matched: Bool
    /// Credits to charge for this reply (0 when nothing useful was found).
    let cost: Int
    /// Set when the matter sounds serious enough to see a real advocate.
    let needsAdvocate: Bool
}

/// MOCK pricing — the UX supports variable per-question costs; the exact
/// production economics are configured here after the AI provider is
/// selected. Never hard-code amounts in views.
nonisolated enum EVakeelPricing {
    static let simpleCost: Int = 1
    static let detailedCost: Int = 2

    /// Longer, multi-part or drafting-style questions cost more.
    static func estimatedCost(for question: String) -> Int {
        let lower = question.lowercased()
        let isLong = question.count > 160
        let multiPart = question.filter { $0 == "?" }.count > 1
        let drafting = ["draft", "notice format", "agreement", "in detail", "step by step", "procedure for", "how do i file"]
            .contains { lower.contains($0) }
        return (isLong || multiPart || drafting) ? detailedCost : simpleCost
    }
}

/// Provider seam — implement this with GPT, Gemini or another API later.
protocol EVakeelProvider {
    func reply(to question: String, data: LegalDataService) async -> EVakeelReply
}

/// Local mock provider: curated everyday scenarios first (realistic
/// step-by-step guidance), then dataset retrieval, in a friendly assistant
/// voice that flags serious matters for a real advocate.
struct MockEVakeelProvider: EVakeelProvider {

    func reply(to question: String, data: LegalDataService) async -> EVakeelReply {
        // A believable thinking pause for the mock.
        try? await Task.sleep(for: .milliseconds(900))

        // Everyday situations (deposits, fraud, notices…) get the curated,
        // practical answers people actually need.
        if let scenario = EVakeelScenarioBank.match(question) {
            return EVakeelReply(
                lead: "Based on the legal information in LexIndia:",
                text: scenario.body,
                mappingNote: nil,
                sectionIds: scenario.sectionIds,
                matched: true,
                cost: EVakeelPricing.estimatedCost(for: question),
                needsAdvocate: scenario.serious || Self.soundsSerious(question)
            )
        }

        let answer = data.answer(for: question)
        let cost = answer.matched ? EVakeelPricing.estimatedCost(for: question) : 0

        return EVakeelReply(
            lead: answer.matched ? answer.lead : nil,
            text: answer.body,
            mappingNote: answer.mappingNote,
            sectionIds: answer.sectionIds,
            matched: answer.matched,
            cost: cost,
            needsAdvocate: Self.soundsSerious(question)
        )
    }

    /// Heuristic escalation — serious personal matters get a gentle
    /// "consult a qualified advocate" advisory with the answer.
    static func soundsSerious(_ question: String) -> Bool {
        let lower = question.lowercased()
        let signals = [
            "arrest", "arrested", "custody", "fir against", "against me",
            "summon", "court date", "hearing tomorrow", "police called",
            "threatened", "jail", "divorce", "dowry case", "bail hearing",
            "chargesheet", "convicted", "notice received"
        ]
        return signals.contains { lower.contains($0) }
    }
}
