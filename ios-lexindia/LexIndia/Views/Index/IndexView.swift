//
//  IndexView.swift
//  LexIndia
//
//  The List — an app-wide index / table of contents. The first screen after
//  sign-in. Every row is either a direct destination or a sub-list that
//  drills deeper (Law Library → Areas → Acts → Chapters → Sections). It is
//  deliberately a flat, scannable index, not another dashboard.
//

import SwiftUI

/// Sub-lists the index can drill into. Hashable so it rides the shared
/// `Destination` navigation path like every other screen.
enum IndexGroup: Hashable {
    case library
    case students
    case documents
    case mySpace
    case settings
    case situations
    case topics
}

/// One entry in an index list — a leaf destination, a drill-down group,
/// or an action (tab switch / overlay).
struct IndexEntry: Identifiable {
    enum Target {
        case destination(Destination)
        case group(IndexGroup)
        case tab(LexTab)
        case evakeel
    }

    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let pastelIndex: Int
    let target: Target
    var trailing: String? = nil
}

struct IndexView: View {
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(LegalDataService.self) private var data

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 14)

                IndexList(title: LexStrings.t("index.explore", store.language), entries: exploreEntries)
                    .padding(.top, 22)
                IndexList(title: LexStrings.t("index.yours", store.language), entries: yoursEntries)
                    .padding(.top, 24)
                IndexList(title: LexStrings.t("index.more", store.language), entries: moreEntries)
                    .padding(.top, 24)

                IndexHintCard()
                    .padding(.top, 24)

                TrustFootnote()
                    .padding(.vertical, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LexStrings.t("tab.list", store.language))
                    .font(LexFont.display(34, .bold))
                    .foregroundStyle(LexColor.ink)
                Text(LexStrings.t("index.subtitle", store.language))
                    .font(LexFont.sans(15))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer()
            LexSearchButton()
        }
    }

    // MARK: Entries

    private var exploreEntries: [IndexEntry] {
        let lang = store.language
        return [
            IndexEntry(id: "library", title: LexStrings.t("tab.library", lang), subtitle: LexStrings.t("index.library.sub", lang), symbol: "building.columns", pastelIndex: 0, target: .group(.library)),
            IndexEntry(id: "students", title: LexStrings.t("tab.students", lang), subtitle: LexStrings.t("index.students.sub", lang), symbol: "graduationcap", pastelIndex: 2, target: .group(.students)),
            IndexEntry(id: "updates", title: LexStrings.t("library.updates", lang), subtitle: LexStrings.t("index.updates.sub", lang), symbol: "newspaper", pastelIndex: 4, target: .destination(.legalUpdates), trailing: "\(LegalUpdatesCatalog.updates.count)"),
            IndexEntry(id: "documents", title: LexStrings.t("library.documentsForms", lang), subtitle: LexStrings.t("index.documents.sub", lang), symbol: "doc.text", pastelIndex: 7, target: .group(.documents), trailing: "\(DocumentCatalog.documents.count)"),
            IndexEntry(id: "ipc", title: "IPC → BNS", subtitle: LexStrings.t("index.ipc.sub", lang), symbol: "arrow.left.arrow.right", pastelIndex: 5, target: .destination(.ipcBns)),
            IndexEntry(id: "situations", title: LexStrings.t("myspace.situations", lang), subtitle: LexStrings.t("index.situations.sub", lang), symbol: "person.text.rectangle", pastelIndex: 1, target: .group(.situations), trailing: "\(data.core.situations.count)"),
            IndexEntry(id: "topics", title: LexStrings.t("library.topics", lang), subtitle: LexStrings.t("index.topics.sub", lang), symbol: "tag", pastelIndex: 3, target: .group(.topics), trailing: "\(data.core.topics.count)")
        ]
    }

    private var yoursEntries: [IndexEntry] {
        let lang = store.language
        return [
            IndexEntry(id: "myspace", title: LexStrings.t("tab.myspace", lang), subtitle: LexStrings.t("index.myspace.sub", lang), symbol: "square.grid.2x2", pastelIndex: 6, target: .group(.mySpace)),
            IndexEntry(id: "evakeel", title: "E-Vakeel", subtitle: LexStrings.t("index.evakeel.sub", lang), symbol: "bubble.left.and.text.bubble.right", pastelIndex: 2, target: .evakeel)
        ]
    }

    private var moreEntries: [IndexEntry] {
        let lang = store.language
        return [
            IndexEntry(id: "settings", title: LexStrings.t("account.settings", lang), subtitle: LexStrings.t("index.settings.sub", lang), symbol: "gearshape", pastelIndex: 4, target: .group(.settings)),
            IndexEntry(id: "account", title: LexStrings.t("tab.account", lang), subtitle: "\(LexStrings.t("myspace.membership", lang)) · \(LexStrings.t("account.credits", lang))", symbol: "person.crop.circle", pastelIndex: 0, target: .tab(.account))
        ]
    }
}

// MARK: - Sub-lists

struct IndexGroupView: View {
    @Environment(UserDataStore.self) private var store
    @Environment(LegalDataService.self) private var data

    let group: IndexGroup

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                IndexGroupHeader(title: title, subtitle: subtitle, symbol: symbol)
                    .padding(.top, 8)

                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    IndexList(title: section.title, entries: section.entries)
                        .padding(.top, index == 0 ? 22 : 24)
                }

                if let hub = hubTab {
                    IndexHubLink(tab: hub, label: LexStrings.f("index.openHub", store.language, title))
                        .padding(.top, 24)
                }

                TrustFootnote()
                    .padding(.vertical, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Section {
        let title: String?
        let entries: [IndexEntry]
    }

    private var lang: AppLanguage { store.language }

    private var title: String {
        switch group {
        case .library: return LexStrings.t("tab.library", lang)
        case .students: return LexStrings.t("tab.students", lang)
        case .documents: return LexStrings.t("library.documentsForms", lang)
        case .mySpace: return LexStrings.t("tab.myspace", lang)
        case .settings: return LexStrings.t("account.settings", lang)
        case .situations: return LexStrings.t("myspace.situations", lang)
        case .topics: return LexStrings.t("library.topics", lang)
        }
    }

    private var subtitle: String {
        switch group {
        case .library: return LexStrings.t("index.library.sub", lang)
        case .students: return LexStrings.t("index.students.sub", lang)
        case .documents: return LexStrings.t("index.documents.sub", lang)
        case .mySpace: return LexStrings.t("index.myspace.sub", lang)
        case .settings: return LexStrings.t("index.settings.sub", lang)
        case .situations: return LexStrings.t("index.situations.sub", lang)
        case .topics: return LexStrings.t("index.topics.sub", lang)
        }
    }

    private var symbol: String {
        switch group {
        case .library: return "building.columns"
        case .students: return "graduationcap"
        case .documents: return "doc.text"
        case .mySpace: return "square.grid.2x2"
        case .settings: return "gearshape"
        case .situations: return "person.text.rectangle"
        case .topics: return "tag"
        }
    }

    /// The hub tab this group mirrors, offered as a single "open the full
    /// hub" link so the index never dead-ends.
    private var hubTab: LexTab? {
        switch group {
        case .library: return .library
        case .students: return .students
        case .mySpace: return .mySpace
        case .settings: return .account
        default: return nil
        }
    }

    private var sections: [Section] {
        switch group {
        case .library: return librarySections
        case .students: return studentsSections
        case .documents: return documentsSections
        case .mySpace: return mySpaceSections
        case .settings: return settingsSections
        case .situations: return [Section(title: nil, entries: situationEntries)]
        case .topics: return [Section(title: nil, entries: topicEntries)]
        }
    }

    private var librarySections: [Section] {
        let areas = data.core.categories.enumerated().map { index, category in
            IndexEntry(
                id: "cat-\(category.id)",
                title: LexLocalize.categoryName(category, lang),
                subtitle: LexLocalize.categoryTagline(category, lang),
                symbol: Self.categorySymbol(category.id),
                pastelIndex: index,
                target: .destination(.category(category.id)),
                trailing: "\(category.actIds.count)"
            )
        }
        let acts = Self.orderedActs(data.core.acts).enumerated().map { index, act in
            IndexEntry(
                id: "act-\(act.id)",
                title: act.displayShortName,
                subtitle: LexLocalize.actName(act, lang),
                symbol: "book.closed",
                pastelIndex: index,
                target: .destination(.act(act.id)),
                trailing: act.chapters.isEmpty ? nil : "\(act.chapters.count)"
            )
        }
        let tools = [
            IndexEntry(id: "ipc", title: "IPC → BNS", subtitle: LexStrings.t("index.ipc.sub", lang), symbol: "arrow.left.arrow.right", pastelIndex: 5, target: .destination(.ipcBns)),
            IndexEntry(id: "defs", title: LexStrings.t("account.definitions", lang), subtitle: LexStrings.t("index.definitions.sub", lang), symbol: "character.book.closed", pastelIndex: 1, target: .destination(.definitions), trailing: "\(data.core.definitions.count)"),
            IndexEntry(id: "cases", title: LexStrings.t("account.caseLaws", lang), subtitle: LexStrings.t("index.caseLaws.sub", lang), symbol: "text.quote", pastelIndex: 3, target: .destination(.caseLaws), trailing: "\(data.core.caseLaws.count)")
        ]
        return [
            Section(title: LexStrings.t("index.areas", lang), entries: areas),
            Section(title: LexStrings.t("index.acts", lang), entries: acts),
            Section(title: LexStrings.t("index.reference", lang), entries: tools)
        ]
    }

    private var studentsSections: [Section] {
        let learn = [
            IndexEntry(id: "quiz", title: LexStrings.t("students.quizzes", lang), subtitle: LexStrings.t("index.quiz.sub", lang), symbol: "checkmark.seal", pastelIndex: 3, target: .destination(.quizzes)),
            IndexEntry(id: "study", title: LexStrings.t("library.study", lang), subtitle: LexStrings.t("index.study.sub", lang), symbol: "graduationcap", pastelIndex: 2, target: .destination(.studyMaterial))
        ]
        let reference = [
            IndexEntry(id: "defs", title: LexStrings.t("account.definitions", lang), subtitle: LexStrings.t("index.definitions.sub", lang), symbol: "character.book.closed", pastelIndex: 1, target: .destination(.definitions)),
            IndexEntry(id: "cases", title: LexStrings.t("account.caseLaws", lang), subtitle: LexStrings.t("index.caseLaws.sub", lang), symbol: "text.quote", pastelIndex: 3, target: .destination(.caseLaws)),
            IndexEntry(id: "ipc", title: "IPC → BNS", subtitle: LexStrings.t("index.ipc.sub", lang), symbol: "arrow.left.arrow.right", pastelIndex: 5, target: .destination(.ipcBns))
        ]
        return [
            Section(title: LexStrings.t("index.learn", lang), entries: learn),
            Section(title: LexStrings.t("index.reference", lang), entries: reference)
        ]
    }

    private var documentsSections: [Section] {
        let kinds = DocumentKind.allCases.enumerated().map { index, kind in
            let count = DocumentCatalog.documents(of: kind).count
            return IndexEntry(
                id: "kind-\(kind.id)",
                title: kind.groupTitle(lang),
                subtitle: kind.groupBlurb(lang),
                symbol: kind.symbol,
                pastelIndex: index,
                target: .destination(.documents),
                trailing: count == 1 ? LexStrings.t("index.oneDoc", lang) : LexStrings.f("index.docCount", lang, count)
            )
        }
        return [Section(title: LexStrings.t("index.docKinds", lang), entries: kinds)]
    }

    private var mySpaceSections: [Section] {
        let entries = [
            IndexEntry(id: "saved", title: LexStrings.t("account.saved", lang), subtitle: LexStrings.t("index.saved.sub", lang), symbol: "bookmark", pastelIndex: 6, target: .destination(.notes), trailing: store.saved.isEmpty ? nil : "\(store.saved.count)"),
            IndexEntry(id: "recents", title: LexStrings.t("account.recents", lang), subtitle: LexStrings.t("index.recents.sub", lang), symbol: "clock", pastelIndex: 0, target: .destination(.recents), trailing: store.recents.isEmpty ? nil : "\(store.recents.count)"),
            IndexEntry(id: "downloads", title: LexStrings.t("account.downloads", lang), subtitle: LexStrings.t("index.downloads.sub", lang), symbol: "arrow.down.circle", pastelIndex: 7, target: .destination(.downloads), trailing: store.downloads.isEmpty ? nil : "\(store.downloads.count)")
        ]
        return [Section(title: nil, entries: entries)]
    }

    private var settingsSections: [Section] {
        let prefs = [
            IndexEntry(id: "appearance", title: LexStrings.t("account.appearance", lang), subtitle: store.themeMode.label(lang), symbol: "circle.lefthalf.filled", pastelIndex: 0, target: .destination(.appearance)),
            IndexEntry(id: "color", title: LexStrings.t("account.appColor", lang), subtitle: ThemeStore.shared.accentName, symbol: "paintpalette", pastelIndex: 5, target: .destination(.appColor)),
            IndexEntry(id: "language", title: LexStrings.t("account.language", lang), subtitle: store.language.nativeName, symbol: "globe", pastelIndex: 2, target: .destination(.language))
        ]
        let about = [
            IndexEntry(id: "privacy", title: LexStrings.t("account.privacy", lang), subtitle: "", symbol: "lock", pastelIndex: 4, target: .destination(.legalPage(.privacy))),
            IndexEntry(id: "terms", title: LexStrings.t("account.terms", lang), subtitle: "", symbol: "doc.plaintext", pastelIndex: 4, target: .destination(.legalPage(.terms))),
            IndexEntry(id: "disclaimer", title: LexStrings.t("account.disclaimer", lang), subtitle: "", symbol: "info.circle", pastelIndex: 4, target: .destination(.legalPage(.disclaimer)))
        ]
        return [
            Section(title: LexStrings.t("account.settings", lang), entries: prefs),
            Section(title: LexStrings.t("account.about", lang), entries: about)
        ]
    }

    private var situationEntries: [IndexEntry] {
        data.core.situations.enumerated().map { index, situation in
            IndexEntry(
                id: "sit-\(situation.id)",
                title: LexLocalize.situationTitle(situation, lang),
                subtitle: LexLocalize.situationBlurb(situation, lang),
                symbol: situation.symbol,
                pastelIndex: index,
                target: .destination(.situation(situation.id)),
                trailing: "\(situation.sectionIds.count) §"
            )
        }
    }

    private var topicEntries: [IndexEntry] {
        data.core.topics.enumerated().map { index, topic in
            IndexEntry(
                id: "topic-\(topic.id)",
                title: LexLocalize.topicName(topic, lang),
                subtitle: "",
                symbol: "tag",
                pastelIndex: index,
                target: .destination(.topic(topic.id)),
                trailing: "\(topic.sectionIds.count) §"
            )
        }
    }

    // MARK: Helpers

    private static let preferredOrder: [String] = [
        "bns", "bnss", "bsa", "contract-act", "it-act-2000", "constitution",
        "cpa-2019", "tpa-1882", "hma-1955", "ida-1947", "ita-1961", "copyright-1957"
    ]

    private static func orderedActs(_ acts: [LegalAct]) -> [LegalAct] {
        let index = Dictionary(uniqueKeysWithValues: preferredOrder.enumerated().map { ($1, $0) })
        return acts.sorted { (index[$0.id] ?? Int.max) < (index[$1.id] ?? Int.max) }
    }

    private static func categorySymbol(_ id: String) -> String {
        switch id {
        case "criminal": return "scale.3d"
        case "constitutional": return "building.columns"
        case "civil": return "doc.text"
        case "property": return "house"
        case "family": return "person.2"
        case "labour": return "briefcase"
        case "taxation": return "percent"
        case "ip-tech": return "laptopcomputer"
        default: return "book"
        }
    }
}

// MARK: - Shared index building blocks

/// A titled block of rows in a single surface card — the index's one
/// visual unit, reused at every depth.
struct IndexList: View {
    let title: String?
    let entries: [IndexEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                LexOverline(text: title)
            }
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 { LexHairline().padding(.leading, 70) }
                    IndexRow(entry: entry)
                }
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }
}

private struct IndexRow: View {
    @Environment(UIState.self) private var ui

    let entry: IndexEntry

    var body: some View {
        switch entry.target {
        case .destination(let destination):
            NavigationLink(value: destination) { label }
                .buttonStyle(LexPressStyle())
        case .group(let group):
            NavigationLink(value: Destination.indexGroup(group)) { label }
                .buttonStyle(LexPressStyle())
        case .tab(let tab):
            Button { ui.openTab(tab) } label: { label }
                .buttonStyle(LexPressStyle())
        case .evakeel:
            Button { ui.openEVakeel() } label: { label }
                .buttonStyle(LexPressStyle())
        }
    }

    private var isGroup: Bool {
        if case .group = entry.target { return true }
        return false
    }

    private var label: some View {
        let pastel = LexColor.pastel(entry.pastelIndex)
        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: entry.symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(pastel.tone)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 12).fill(pastel.fill))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(LexFont.display(17, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !entry.subtitle.isEmpty {
                    Text(entry.subtitle)
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 8)
            if let trailing = entry.trailing {
                Text(trailing)
                    .font(LexFont.sans(12, .semibold).monospacedDigit())
                    .foregroundStyle(LexColor.slate)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(LexColor.canvas))
            }
            Image(systemName: isGroup ? "chevron.right.2" : "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isGroup ? LexColor.brand : LexColor.faint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title). \(entry.subtitle)")
        .accessibilityHint(isGroup ? "Opens a list" : "")
    }
}

/// Sub-list header: brand-soft card with the group's icon, mirroring the
/// hub headers without becoming a dashboard.
private struct IndexGroupHeader: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(LexColor.onBrand))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LexFont.display(24, .bold))
                    .foregroundStyle(LexColor.ink)
                Text(subtitle)
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.brandSoft)
        .clipShape(.rect(cornerRadius: 18))
    }
}

/// "Open the full hub" — switches tabs so a sub-list is never a dead end.
private struct IndexHubLink: View {
    @Environment(UIState.self) private var ui

    let tab: LexTab
    let label: String

    var body: some View {
        Button {
            ui.openTab(tab)
        } label: {
            HStack(spacing: 8) {
                Text(label)
                    .font(LexFont.sans(14, .semibold))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(LexColor.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(LexColor.brandSoft)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }
}

/// Footer hint on the root index: search or ask E-Vakeel.
private struct IndexHintCard: View {
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        Button {
            ui.activateSearch()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LexColor.brand)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.onBrand))
                Text(LexStrings.t("index.hint", store.language))
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.brandSoft)
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }
}
