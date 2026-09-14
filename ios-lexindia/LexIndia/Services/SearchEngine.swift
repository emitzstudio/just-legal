//
//  SearchEngine.swift
//  LexIndia
//
//  Local search across sections, acts, definitions, case laws and
//  IPC → BNS mappings, with human-readable match reasons.
//

import Foundation

struct SectionHit: Identifiable {
    let section: LegalSection
    let reason: String?
    var id: String { section.id }
}

struct SearchResults {
    var mappings: [IPCMapping] = []
    var sections: [SectionHit] = []
    var definitions: [LegalDefinition] = []
    var acts: [LegalAct] = []
    var topics: [LegalTopic] = []
    var caseLaws: [CaseLaw] = []

    var isEmpty: Bool {
        mappings.isEmpty && sections.isEmpty && definitions.isEmpty && acts.isEmpty && topics.isEmpty && caseLaws.isEmpty
    }
}

extension LegalDataService {

    func search(_ rawQuery: String) -> SearchResults {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return SearchResults() }

        let tokens = query
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        let numericTokens = tokens.filter { $0.first?.isNumber == true }

        var results = SearchResults()

        // IPC → BNS mappings: "420", "ipc 302", "sedition"
        results.mappings = core.ipcMappings.filter { mapping in
            let ipcLower = mapping.ipc.lowercased()
            if numericTokens.contains(where: { ipcLower.contains($0) }) { return true }
            if query.count > 3 && mapping.ipcTitle.lowercased().contains(query) { return true }
            return false
        }
        if results.mappings.count > 6 {
            results.mappings = Array(results.mappings.prefix(6))
        }

        // Sections, scored.
        var scored: [(LegalSection, Int, String?)] = []
        for section in sections {
            var score = 0
            var reason: String?
            let titleLower = section.title.lowercased()
            let numberLower = section.number.lowercased()

            if numberLower == query {
                score = max(score, 100)
            } else if tokens.contains(numberLower) {
                score = max(score, 95)
            } else if !numericTokens.isEmpty && numericTokens.contains(where: { numberLower.hasPrefix($0) }) {
                score = max(score, 62)
            }

            if let ipcLabel = section.ipcLabel {
                let ipcLower = ipcLabel.lowercased()
                if numericTokens.contains(where: { ipcLower.contains($0) }) {
                    if score < 80 {
                        score = 80
                        reason = "Earlier \(ipcLabel)"
                    }
                }
            }

            if titleLower == query {
                score = max(score, 92)
            } else if query.count > 2 && titleLower.contains(query) {
                score = max(score, 60)
            } else if tokens.contains(where: { $0.count > 2 && titleLower.contains($0) }) {
                score = max(score, 38)
            }

            for keyword in section.keywords {
                if keyword == query {
                    score = max(score, 66)
                } else if tokens.contains(keyword) {
                    score = max(score, 48)
                    if reason == nil && !titleLower.contains(keyword) {
                        reason = "Covers \u{201C}\(keyword)\u{201D}"
                    }
                } else if query.count > 3 && keyword.contains(query) {
                    score = max(score, 34)
                    if reason == nil { reason = "Covers \u{201C}\(keyword)\u{201D}" }
                }
            }

            if score == 0 && query.count > 4 && section.explanation.lowercased().contains(query) {
                score = 18
                reason = "Mentioned in the plain-language guide"
            }

            if score > 0 {
                scored.append((section, score, reason))
            }
        }
        results.sections = scored
            .sorted { $0.1 > $1.1 }
            .prefix(12)
            .map { SectionHit(section: $0.0, reason: $0.2) }

        // Acts.
        results.acts = core.acts.filter { act in
            let nameLower = act.name.lowercased()
            let shortLower = act.shortName?.lowercased() ?? ""
            if query.count >= 2 && (nameLower.contains(query) || shortLower == query) { return true }
            return tokens.contains(where: { $0.count > 2 && (nameLower.contains($0) || shortLower == $0) })
        }
        if results.acts.count > 4 { results.acts = Array(results.acts.prefix(4)) }

        // Definitions.
        results.definitions = core.definitions.filter { definition in
            let termLower = definition.term.lowercased()
            if query.count >= 2 && termLower.contains(query) { return true }
            if tokens.contains(where: { $0.count > 3 && termLower.contains($0) }) { return true }
            if query.count > 4 && definition.meaning.lowercased().contains(query) { return true }
            return false
        }
        if results.definitions.count > 5 { results.definitions = Array(results.definitions.prefix(5)) }

        // Topics.
        results.topics = core.topics.filter { topic in
            let nameLower = topic.name.lowercased()
            if query.count >= 3 && nameLower.contains(query) { return true }
            return tokens.contains(where: { $0.count > 3 && nameLower.contains($0) })
        }
        if results.topics.count > 3 { results.topics = Array(results.topics.prefix(3)) }

        // Case laws.
        results.caseLaws = core.caseLaws.filter { caseLaw in
            let titleLower = caseLaw.title.lowercased()
            if query.count > 3 && titleLower.contains(query) { return true }
            if tokens.contains(where: { $0.count > 3 && titleLower.contains($0) }) { return true }
            if query.count > 4 && caseLaw.principle.lowercased().contains(query) { return true }
            return false
        }
        if results.caseLaws.count > 4 { results.caseLaws = Array(results.caseLaws.prefix(4)) }

        return results
    }
}
