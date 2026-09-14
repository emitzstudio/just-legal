//
//  GlobalSearch.swift
//  LexIndia
//
//  Universal search across the whole product: the legal library, documents,
//  Students Corner, legal updates, the user's own space and settings.
//  Results come back grouped by source so the search screen can present
//  them under clear headings.
//

import Foundation

/// A settings destination that universal search can surface.
struct SettingsSearchEntry: Identifiable {
    let id: String
    /// LexStrings key for the row title.
    let titleKey: String
    let symbol: String
    /// Where the row navigates; nil when it opens the plans sheet instead.
    let destination: Destination?
    let opensPlans: Bool
    /// Lowercased match terms (English + Hindi).
    let matchTerms: [String]
}

enum SettingsSearchCatalog {
    static let entries: [SettingsSearchEntry] = [
        SettingsSearchEntry(
            id: "s-appearance", titleKey: "account.appearance", symbol: "circle.lefthalf.filled",
            destination: .appearance, opensPlans: false,
            matchTerms: ["appearance", "theme", "dark", "light", "mode", "थीम", "डार्क", "लाइट"]
        ),
        SettingsSearchEntry(
            id: "s-language", titleKey: "account.language", symbol: "globe",
            destination: .language, opensPlans: false,
            matchTerms: ["language", "hindi", "english", "भाषा", "हिन्दी", "इंग्लिश"]
        ),
        SettingsSearchEntry(
            id: "s-appcolor", titleKey: "account.appColor", symbol: "paintpalette",
            destination: .appColor, opensPlans: false,
            matchTerms: ["colour", "color", "accent", "paint", "रंग", "कलर"]
        ),
        SettingsSearchEntry(
            id: "s-credits", titleKey: "account.credits.history", symbol: "clock.arrow.circlepath",
            destination: .creditHistory, opensPlans: false,
            matchTerms: ["credit", "credits", "balance", "क्रेडिट", "बैलेंस"]
        ),
        SettingsSearchEntry(
            id: "s-downloads", titleKey: "account.downloads", symbol: "arrow.down.circle",
            destination: .downloads, opensPlans: false,
            matchTerms: ["download", "downloads", "pdf", "डाउनलोड"]
        ),
        SettingsSearchEntry(
            id: "s-plans", titleKey: "account.membership", symbol: "laurel.leading",
            destination: nil, opensPlans: true,
            matchTerms: ["plan", "plans", "subscription", "membership", "price", "प्लान", "सदस्यता"]
        ),
        SettingsSearchEntry(
            id: "s-notes", titleKey: "account.saved", symbol: "bookmark",
            destination: .notes, opensPlans: false,
            matchTerms: ["saved", "notes", "bookmark", "नोट", "सेव"]
        ),
        SettingsSearchEntry(
            id: "s-recents", titleKey: "account.recents", symbol: "clock",
            destination: .recents, opensPlans: false,
            matchTerms: ["recent", "recently", "history", "हाल"]
        )
    ]
}

/// Grouped results for the universal search screen.
struct GlobalSearchResults {
    var core: SearchResults = SearchResults()
    var documents: [LexDocument] = []
    var studentDocs: [LexDocument] = []
    var quizzesMatch: Bool = false
    var updates: [LegalUpdate] = []
    var savedSections: [LegalSection] = []
    var settings: [SettingsSearchEntry] = []

    var isEmpty: Bool {
        core.isEmpty && documents.isEmpty && studentDocs.isEmpty && !quizzesMatch
            && updates.isEmpty && savedSections.isEmpty && settings.isEmpty
    }
}

extension LegalDataService {

    /// Searches every surface of LexIndia for the universal search screen.
    func globalSearch(_ rawQuery: String, store: UserDataStore) -> GlobalSearchResults {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var results = GlobalSearchResults()
        guard !query.isEmpty else { return results }

        results.core = search(rawQuery)

        guard query.count >= 2 else { return results }

        // Documents (bare acts + court forms) and student material.
        let matchesDocument: (LexDocument) -> Bool = { document in
            if document.title.lowercased().contains(query) { return true }
            if query.count > 3 && document.summary.lowercased().contains(query) { return true }
            return document.kind.groupTitle.lowercased().contains(query)
        }
        results.documents = Array(
            DocumentCatalog.documents
                .filter { ($0.kind == .bareAct || $0.kind == .courtForm) && matchesDocument($0) }
                .prefix(5)
        )
        results.studentDocs = Array(
            DocumentCatalog.documents
                .filter { [.examNote, .previousPaper, .revision].contains($0.kind) && matchesDocument($0) }
                .prefix(5)
        )

        // Quizzes.
        let quizTerms = ["quiz", "क्विज", "mcq", "practice test", "प्रश्नोत्तरी"]
        results.quizzesMatch = quizTerms.contains { query.contains($0) || $0.contains(query) && query.count >= 3 }

        // Legal updates.
        if query.count >= 3 {
            results.updates = Array(
                LegalUpdatesCatalog.updates
                    .filter {
                        $0.title.lowercased().contains(query)
                            || $0.snippet.lowercased().contains(query)
                            || $0.category.label.lowercased().contains(query)
                    }
                    .prefix(4)
            )
        }

        // The user's own space — saved sections whose title or number match.
        results.savedSections = Array(
            store.saved
                .compactMap { section($0.sectionId) }
                .filter { $0.title.lowercased().contains(query) || $0.number.lowercased() == query }
                .prefix(4)
        )

        // Settings.
        results.settings = SettingsSearchCatalog.entries.filter { entry in
            entry.matchTerms.contains { term in
                term.contains(query) || query.contains(term)
            }
        }

        return results
    }
}
