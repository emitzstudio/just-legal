//
//  AskEngine.swift
//  LexIndia
//
//  Local retrieval that grounds every E-Vakeel answer in the bundled
//  legal dataset. The mock provider builds on this; a real AI provider
//  can replace it without UI changes.
//

import Foundation

struct AskAnswer {
    let matched: Bool
    let lead: String
    let body: String
    let example: String?
    let mappingNote: String?
    let sectionIds: [String]
    let definitionIds: [String]
}

extension LegalDataService {

    func answer(for rawQuery: String) -> AskAnswer {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let lead = "Based on the legal information in LexIndia:"

        guard !query.isEmpty else {
            return AskAnswer(matched: false, lead: lead, body: "", example: nil, mappingNote: nil, sectionIds: [], definitionIds: [])
        }

        let results = search(query)

        // If the question is essentially an IPC number, translate it first.
        var mappingNote: String?
        let numericOnly = query.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.first?.isNumber == true }
        if let mapping = results.mappings.first,
           numericOnly.contains(where: { mapping.ipc.lowercased().contains($0) }) {
            mappingNote = "IPC \(mapping.ipc) — \(mapping.ipcTitle) — is now Section \(mapping.bnsLabel) of the Bharatiya Nyaya Sanhita, 2023."
        }

        // Prefer a definition when the query reads like a glossary lookup and
        // the definition matches at least as well as any section.
        let queryLower = query.lowercased()
        let asksForMeaning = queryLower.hasPrefix("what is") || queryLower.hasPrefix("what does")
            || queryLower.contains("meaning of") || queryLower.hasPrefix("define")
        if asksForMeaning,
           let definition = results.definitions.first,
           queryLower.contains(definition.term.lowercased().prefix(6).lowercased()) || results.sections.isEmpty {
            return AskAnswer(
                matched: true,
                lead: lead,
                body: definition.meaning,
                example: nil,
                mappingNote: mappingNote,
                sectionIds: Array(definition.relatedSectionIds.prefix(2)),
                definitionIds: [definition.id]
            )
        }

        // Prefer a section with a hand-written guide among the top hits, so
        // answers quote a real explanation rather than a placeholder.
        let topHits = results.sections.prefix(3)
        let bestSection = topHits.first(where: { $0.section.hasGuide })?.section ?? results.sections.first?.section
        if let best = bestSection {
            var provisionIds: [String] = [best.id]
            for related in best.relatedSectionIds where provisionIds.count < 3 {
                if results.sections.contains(where: { $0.section.id == related && $0.section.id != best.id }) {
                    provisionIds.append(related)
                }
            }
            if provisionIds.count == 1, let second = results.sections.first(where: { $0.section.id != best.id })?.section {
                provisionIds.append(second.id)
            }
            let body: String
            if best.hasGuide {
                body = best.explanation
            } else {
                let actName = act(best.actId)?.displayShortName ?? "the law"
                body = "Section \(best.number) of \(actName) — \(best.title) — covers this. Its full official text is available in the reader below; the plain-language LexIndia guide for it is being prepared."
            }
            return AskAnswer(
                matched: true,
                lead: lead,
                body: body,
                example: best.hasGuide ? best.example : nil,
                mappingNote: mappingNote,
                sectionIds: provisionIds,
                definitionIds: Array(best.definitionIds.prefix(2))
            )
        }

        if let definition = results.definitions.first {
            return AskAnswer(
                matched: true,
                lead: lead,
                body: definition.meaning,
                example: nil,
                mappingNote: mappingNote,
                sectionIds: Array(definition.relatedSectionIds.prefix(2)),
                definitionIds: [definition.id]
            )
        }

        return AskAnswer(
            matched: false,
            lead: lead,
            body: "I couldn't find this in the legal information currently available in LexIndia. Try asking with a section number (like 318), a legal term (like cheating), or browse the Library.",
            example: nil,
            mappingNote: mappingNote,
            sectionIds: [],
            definitionIds: []
        )
    }
}
