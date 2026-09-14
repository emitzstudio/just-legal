//
//  LegalDataService.swift
//  LexIndia
//
//  Loads the bundled structured legal dataset and provides indexed access.
//

import Foundation
import Observation

@Observable
final class LegalDataService {
    private(set) var core: LegalCore = .empty
    private(set) var sections: [LegalSection] = []
    private(set) var loadFailed: Bool = false

    private var sectionById: [String: LegalSection] = [:]
    private var actById: [String: LegalAct] = [:]
    private var chapterById: [String: LegalChapter] = [:]
    private var chapterActId: [String: String] = [:]
    private var categoryById: [String: LegalCategory] = [:]
    private var definitionById: [String: LegalDefinition] = [:]
    private var caseLawById: [String: CaseLaw] = [:]
    private var situationById: [String: Situation] = [:]
    private var topicById: [String: LegalTopic] = [:]
    private var sectionsByAct: [String: [LegalSection]] = [:]
    private var sectionsByChapter: [String: [LegalSection]] = [:]

    init() {
        load()
    }

    private func load() {
        guard let loadedCore: LegalCore = Self.decodeResource("LegalCore") else {
            loadFailed = true
            print("[LexIndia] Failed to load LegalCore.json")
            return
        }
        var loadedSections: [LegalSection] = []
        let bnsChapterFiles = (1...20).map { String(format: "BNS_Ch%02d", $0) }
        for resource in bnsChapterFiles + ["SectionsOther"] {
            if let part: [LegalSection] = Self.decodeResource(resource) {
                loadedSections.append(contentsOf: part)
            } else {
                print("[LexIndia] Failed to load \(resource).json")
            }
        }
        core = loadedCore
        sections = loadedSections.sorted { $0.sortIndex < $1.sortIndex }
        buildIndexes()
    }

    private func buildIndexes() {
        sectionById = Dictionary(uniqueKeysWithValues: sections.map { ($0.id, $0) })
        actById = Dictionary(uniqueKeysWithValues: core.acts.map { ($0.id, $0) })
        categoryById = Dictionary(uniqueKeysWithValues: core.categories.map { ($0.id, $0) })
        definitionById = Dictionary(uniqueKeysWithValues: core.definitions.map { ($0.id, $0) })
        caseLawById = Dictionary(uniqueKeysWithValues: core.caseLaws.map { ($0.id, $0) })
        situationById = Dictionary(uniqueKeysWithValues: core.situations.map { ($0.id, $0) })
        topicById = Dictionary(uniqueKeysWithValues: core.topics.map { ($0.id, $0) })
        for act in core.acts {
            for chapter in act.chapters {
                chapterById[chapter.id] = chapter
                chapterActId[chapter.id] = act.id
            }
        }
        sectionsByAct = Dictionary(grouping: sections, by: { $0.actId })
            .mapValues { $0.sorted { $0.sortIndex < $1.sortIndex } }
        sectionsByChapter = Dictionary(grouping: sections, by: { $0.chapterId })
            .mapValues { $0.sorted { $0.sortIndex < $1.sortIndex } }
    }

    private static func decodeResource<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Lookups

    func act(_ id: String) -> LegalAct? { actById[id] }
    func section(_ id: String) -> LegalSection? { sectionById[id] }
    func chapter(_ id: String) -> LegalChapter? { chapterById[id] }
    func actId(forChapter chapterId: String) -> String? { chapterActId[chapterId] }
    func category(_ id: String) -> LegalCategory? { categoryById[id] }
    func definition(_ id: String) -> LegalDefinition? { definitionById[id] }
    func caseLaw(_ id: String) -> CaseLaw? { caseLawById[id] }
    func situation(_ id: String) -> Situation? { situationById[id] }
    func topic(_ id: String) -> LegalTopic? { topicById[id] }

    func sections(inAct actId: String) -> [LegalSection] {
        sectionsByAct[actId] ?? []
    }

    func sections(inChapter chapterId: String) -> [LegalSection] {
        sectionsByChapter[chapterId] ?? []
    }

    func acts(inCategory categoryId: String) -> [LegalAct] {
        guard let category = categoryById[categoryId] else { return [] }
        return category.actIds.compactMap { actById[$0] }
    }

    func guidedCount(inCategory categoryId: String) -> Int {
        acts(inCategory: categoryId).reduce(0) { $0 + sections(inAct: $1.id).count }
    }

    /// Previous and next loaded sections within the same Act.
    func neighbors(of section: LegalSection) -> (previous: LegalSection?, next: LegalSection?) {
        let list = sections(inAct: section.actId)
        guard let index = list.firstIndex(where: { $0.id == section.id }) else { return (nil, nil) }
        let previous = index > 0 ? list[index - 1] : nil
        let next = index < list.count - 1 ? list[index + 1] : nil
        return (previous, next)
    }

    /// Full location line, e.g. "Chapter XVII · Of Offences Against Property".
    func chapterLine(for section: LegalSection) -> String? {
        guard let chapter = chapterById[section.chapterId] else { return nil }
        return "Chapter \(chapter.numeral) · \(chapter.title)"
    }
}
