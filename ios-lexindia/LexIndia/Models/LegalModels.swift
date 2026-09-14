//
//  LegalModels.swift
//  LexIndia
//
//  Structured content layer. The UI renders these fields dynamically so the
//  legal dataset can be populated or replaced without redesigning screens.
//

import Foundation

nonisolated struct LegalCore: Codable {
    let categories: [LegalCategory]
    let acts: [LegalAct]
    let definitions: [LegalDefinition]
    let caseLaws: [CaseLaw]
    let ipcMappings: [IPCMapping]
    let situations: [Situation]
    let topics: [LegalTopic]
    let popularSearches: [String]
    let askSuggestions: [String]

    static let empty = LegalCore(
        categories: [], acts: [], definitions: [], caseLaws: [],
        ipcMappings: [], situations: [], topics: [], popularSearches: [], askSuggestions: []
    )
}

nonisolated struct LegalCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let actIds: [String]
    let extentLabel: String
}

nonisolated struct LegalAct: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String?
    let categoryId: String
    let summary: String
    /// "available" when guided sections exist, "preparing" otherwise.
    let status: String
    let extentLabel: String
    let effectiveLabel: String
    let sourceLabel: String
    let chapters: [LegalChapter]

    var isPreparing: Bool { status == "preparing" }
    var displayShortName: String { shortName ?? name }
}

nonisolated struct LegalChapter: Codable, Identifiable, Hashable {
    let id: String
    let numeral: String
    let title: String
    let rangeLabel: String
}

nonisolated struct LegalSection: Codable, Identifiable, Hashable {
    let id: String
    let actId: String
    let chapterId: String
    let number: String
    let sortIndex: Int
    let title: String
    let officialText: String?
    /// "full", "extract", or "unavailable".
    let officialStatus: String
    let textNote: String?
    let explanation: String
    let example: String?
    let keyPoints: [String]
    let relatedSectionIds: [String]
    let caseLawIds: [String]
    let definitionIds: [String]
    let ipcLabel: String?
    let keywords: [String]
    /// True when a hand-written LexIndia guide (explanation, example, key
    /// points) exists; false/nil for sections carrying official text only.
    let curated: Bool?

    var hasOfficialText: Bool { officialStatus != "unavailable" && officialText != nil }
    var isExtract: Bool { officialStatus == "extract" }
    var hasGuide: Bool { curated == true }
}

nonisolated struct LegalDefinition: Codable, Identifiable, Hashable {
    let id: String
    let term: String
    let meaning: String
    let sourceNote: String?
    let relatedSectionIds: [String]
    let relatedCaseLawIds: [String]
}

nonisolated struct CaseLaw: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let court: String
    let year: Int
    let principle: String
    let summary: String
    let relatedSectionIds: [String]
}

nonisolated struct IPCMapping: Codable, Identifiable, Hashable {
    let id: String
    let ipc: String
    let ipcTitle: String
    let bnsLabel: String
    let sectionId: String?
    let note: String?
}

nonisolated struct Situation: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let blurb: String
    let symbol: String
    let intro: String
    let sectionIds: [String]
    let definitionIds: [String]
}

nonisolated struct LegalTopic: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let sectionIds: [String]
}
