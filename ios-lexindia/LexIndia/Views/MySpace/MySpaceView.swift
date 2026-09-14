//
//  MySpaceView.swift
//  LexIndia
//
//  The user's personal area — "everything that belongs to me":
//  continue reading, legal categories, recents, saved sections and
//  notes, downloads, membership status and the quiz shortcut.
//

import SwiftUI

struct MySpaceView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(AccessStore.self) private var access

    /// Major codes first, then the other Acts — same order as the Law Library.
    private static let preferredOrder: [String] = [
        "bns", "bnss", "bsa", "contract-act", "it-act-2000", "constitution",
        "cpa-2019", "tpa-1882", "hma-1955", "ida-1947", "ita-1961", "copyright-1957"
    ]

    private var orderedActs: [LegalAct] {
        let index = Dictionary(uniqueKeysWithValues: Self.preferredOrder.enumerated().map { ($1, $0) })
        return data.core.acts.sorted {
            (index[$0.id] ?? Int.max) < (index[$1.id] ?? Int.max)
        }
    }

    private let toolColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var greetingKey: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "greeting.morning"
        case 12..<17: return "greeting.afternoon"
        default: return "greeting.evening"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .padding(.top, 14)
                if access.isOnTrial {
                    trialBanner
                        .padding(.top, 12)
                }
                statusStrip
                    .padding(.top, 12)
                studyToolsBlock
                    .padding(.top, 26)
                categoriesBlock
                    .padding(.top, 26)
                browseCodesBlock
                    .padding(.top, 26)
                continueBlock
                    .padding(.top, 26)
                situationsBlock
                    .padding(.top, 28)
                topicsBlock
                    .padding(.top, 28)
                recentsBlock
                    .padding(.top, 28)
                savedBlock
                    .padding(.top, 28)
                downloadsBlock
                    .padding(.top, 28)
                TrustFootnote()
                    .padding(.top, 32)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                LexOverline(text: LexStrings.t(greetingKey, store.language), color: LexColor.onBrand.opacity(0.62))
                Spacer()
                AccentDiamond(size: 7, color: LexColor.onBrand)
            }
            Text(store.profileName)
                .font(LexFont.display(30, .bold))
                .foregroundStyle(LexColor.onBrand)
                .padding(.top, 6)
            Text(LexStrings.t("myspace.tagline", store.language))
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.onBrand.opacity(0.78))
                .padding(.top, 5)
            searchField
                .padding(.top, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.brand)
        .clipShape(.rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("My Space. \(store.profileName). Search laws, sections, terms")
    }

    private var searchField: some View {
        Button {
            ui.activateSearch()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LexColor.slate)
                Text(LexStrings.t("myspace.searchPlaceholder", store.language))
                    .font(LexFont.sans(16))
                    .foregroundStyle(LexColor.slate)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 13))
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Search laws, sections, terms")
    }

    // MARK: Trial banner

    private var trialBanner: some View {
        Button {
            ui.plansPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LexColor.saffronDeep)
                VStack(alignment: .leading, spacing: 1) {
                    Text(LexStrings.t("myspace.trial", store.language))
                        .font(LexFont.sans(14, .semibold))
                        .foregroundStyle(LexColor.ink)
                    if let remaining = access.trialRemaining {
                        Text("\(LexStrings.t("myspace.trial.endsIn", store.language)) \(AccessStore.remainingLabel(remaining))")
                            .font(LexFont.sans(12))
                            .foregroundStyle(LexColor.slate)
                    }
                }
                Spacer()
                Text(LexStrings.t("myspace.seePlans", store.language))
                    .font(LexFont.sans(13, .semibold))
                    .foregroundStyle(LexColor.brand)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(LexColor.saffronSoft)
            .clipShape(.rect(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Free trial active. See plans")
    }

    // MARK: Membership + credits

    private var membershipTitle: String {
        if let info = access.subscriptionInfo {
            return "\(LexLocalize.planDuration(months: info.plan.months, store.language)) \(LexStrings.t("plan.suffix", store.language))"
        }
        if access.isOnTrial { return LexStrings.t("myspace.trial", store.language) }
        if access.isDevAccess { return LexStrings.t("account.testAccess", store.language) }
        return LexStrings.t("account.noPlan", store.language)
    }

    private var membershipSub: String {
        if let info = access.subscriptionInfo {
            return LexStrings.f("myspace.until", store.language, LexLocalize.date(info.end, store.language))
        }
        if access.isOnTrial, let remaining = access.trialRemaining {
            return "\(LexStrings.t("myspace.trial.endsIn", store.language)) \(LexLocalize.remaining(remaining, store.language))"
        }
        if access.isDevAccess { return LexStrings.t("account.devOnly", store.language) }
        return LexStrings.t("myspace.seePlans", store.language)
    }

    private var statusStrip: some View {
        HStack(spacing: 12) {
            statusCard(
                overline: LexStrings.t("myspace.membership", store.language),
                symbol: "laurel.leading",
                pastelIndex: 0,
                title: membershipTitle,
                sub: membershipSub
            ) {
                ui.plansPresented = true
            }
            statusCard(
                overline: LexStrings.t("myspace.quiz.title", store.language),
                symbol: "checkmark.seal",
                pastelIndex: 3,
                title: LexStrings.t("students.quizzes", store.language),
                sub: LexStrings.t(store.isWeeklyQuizRewardAvailable ? "myspace.quiz.available" : "myspace.quiz.claimed", store.language)
            ) {
                ui.openQuizzes()
            }
        }
    }

    private func statusCard(overline: String, symbol: String, pastelIndex: Int, title: String, sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LexColor.pastel(pastelIndex).tone)
                        .frame(width: 30, height: 30)
                        .background(RoundedRectangle(cornerRadius: 9).fill(LexColor.pastel(pastelIndex).fill))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LexColor.faint)
                }
                Text(title)
                    .font(LexFont.display(19, .bold).monospacedDigit())
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                VStack(alignment: .leading, spacing: 1) {
                    LexOverline(text: overline)
                    Text(sub)
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(overline): \(title). \(sub)")
    }

    // MARK: Study tools

    private var studyToolsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: LexStrings.t("myspace.studyTools", store.language))
            LazyVGrid(columns: toolColumns, spacing: 12) {
                studyToolTile(
                    title: LexStrings.t("account.definitions", store.language),
                    subtitle: LexStrings.t("myspace.tool.defs", store.language),
                    symbol: "character.book.closed",
                    pastelIndex: 1,
                    destination: .definitions
                )
                studyToolTile(
                    title: LexStrings.t("account.caseLaws", store.language),
                    subtitle: LexStrings.t("myspace.tool.cases", store.language),
                    symbol: "text.quote",
                    pastelIndex: 3,
                    destination: .caseLaws
                )
                studyToolTile(
                    title: "IPC → BNS",
                    subtitle: LexStrings.t("myspace.tool.ipc", store.language),
                    symbol: "arrow.left.arrow.right",
                    pastelIndex: 5,
                    destination: .ipcBns
                )
                studyToolTile(
                    title: LexStrings.t("library.study", store.language),
                    subtitle: LexStrings.t("myspace.tool.study", store.language),
                    symbol: "graduationcap",
                    pastelIndex: 2,
                    destination: .studyMaterial
                )
            }
        }
    }

    private func studyToolTile(title: String, subtitle: String, symbol: String, pastelIndex: Int, destination: Destination) -> some View {
        let pastel = LexColor.pastel(pastelIndex)
        return NavigationLink(value: destination) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(pastel.tone)
                        .frame(width: 34, height: 34)
                        .background(RoundedRectangle(cornerRadius: 10).fill(pastel.fill))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LexColor.faint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LexFont.display(16, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(subtitle)
                        .font(LexFont.sans(11))
                        .foregroundStyle(LexColor.slate)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(title). \(subtitle)")
    }

    // MARK: Legal categories

    private var categoriesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                LexOverline(text: LexStrings.t("myspace.categories", store.language))
                Text(LexStrings.t("myspace.categories.sub", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            LazyVGrid(columns: toolColumns, spacing: 12) {
                ForEach(Array(data.core.categories.enumerated()), id: \.element.id) { index, category in
                    categoryTile(category, index: index)
                }
            }
        }
    }

    private func categoryTile(_ category: LegalCategory, index: Int) -> some View {
        let pastel = LexColor.pastel(index)
        return NavigationLink(value: Destination.category(category.id)) {
            HStack(spacing: 10) {
                Text(String(category.name.prefix(1)))
                    .font(LexFont.display(15, .bold))
                    .foregroundStyle(pastel.tone)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10).fill(pastel.fill))
                VStack(alignment: .leading, spacing: 1) {
                    Text(LexLocalize.categoryName(category, store.language))
                        .font(LexFont.sans(14, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(LexLocalize.categoryTagline(category, store.language))
                        .font(LexFont.sans(11))
                        .foregroundStyle(LexColor.slate)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(LexLocalize.categoryName(category, store.language)). \(LexLocalize.categoryTagline(category, store.language))")
    }

    // MARK: Browse the codes

    private var browseCodesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LexOverline(text: LexStrings.t("myspace.browseCodes", store.language))
                Spacer()
                Button {
                    ui.selectedTab = .library
                } label: {
                    Text(LexStrings.t("myspace.allLaws", store.language))
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.brand)
                }
                .accessibilityLabel("All laws, opens the Law Library")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(orderedActs) { act in
                        NavigationLink(value: Destination.act(act.id)) {
                            Text(act.displayShortName)
                                .font(LexFont.sans(14, .semibold))
                                .foregroundStyle(LexColor.ink)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(LexColor.surface))
                                .overlay(Capsule().strokeBorder(LexColor.hairline, lineWidth: 1))
                        }
                        .buttonStyle(LexPressStyle())
                        .accessibilityLabel(LexLocalize.actName(act, store.language))
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Continue reading

    @ViewBuilder
    private var continueBlock: some View {
        if let recent = store.recents.first,
           let section = data.section(recent.sectionId),
           let act = data.act(section.actId) {
            continueCard(
                overline: LexStrings.t("myspace.continueReading", store.language),
                section: section,
                subtitle: LexLocalize.actName(act, store.language)
            )
        } else if let starter = data.section("bns-318"),
                  let act = data.act(starter.actId) {
            continueCard(
                overline: LexStrings.t("myspace.startClassic", store.language),
                section: starter,
                subtitle: LexLocalize.actName(act, store.language)
            )
        }
    }

    private func continueCard(overline: String, section: LegalSection, subtitle: String) -> some View {
        NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
            VStack(alignment: .leading, spacing: 10) {
                LexOverline(text: overline)
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(section.number)
                        .font(LexFont.display(28, .bold).monospacedDigit())
                        .foregroundStyle(LexColor.brand)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(LexFont.display(18, .semibold))
                            .foregroundStyle(LexColor.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(subtitle)
                            .font(LexFont.sans(13))
                            .foregroundStyle(LexColor.slate)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LexColor.brand)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }

    // MARK: What are you dealing with?

    private var situationsBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            LexOverline(text: LexStrings.t("myspace.situations", store.language))
                .padding(.bottom, 4)
            ForEach(Array(data.core.situations.enumerated()), id: \.element.id) { index, situation in
                if index > 0 { LexHairline() }
                NavigationLink(value: Destination.situation(situation.id)) {
                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: situation.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(LexColor.pastel(index).tone)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LexColor.pastel(index).fill)
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(LexLocalize.situationTitle(situation, store.language))
                                .font(LexFont.display(17, .semibold))
                                .foregroundStyle(LexColor.ink)
                            Text(LexLocalize.situationBlurb(situation, store.language))
                                .font(LexFont.sans(13))
                                .foregroundStyle(LexColor.slate)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LexColor.faint)
                    }
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(LexPressStyle())
                .accessibilityLabel("\(LexLocalize.situationTitle(situation, store.language)). \(LexLocalize.situationBlurb(situation, store.language))")
            }
        }
    }

    // MARK: Relevant topics

    private var topicsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("myspace.topics", store.language))
            FlowLayout(spacing: 8) {
                ForEach(data.core.topics) { topic in
                    NavigationLink(value: Destination.topic(topic.id)) {
                        Text(LexLocalize.topicName(topic, store.language))
                            .font(LexFont.sans(14, .medium))
                            .foregroundStyle(LexColor.brand)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(LexColor.brandSoft)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    // MARK: Recently viewed

    @ViewBuilder
    private var recentsBlock: some View {
        if !store.recents.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                blockHeader(LexStrings.t("myspace.recents", store.language), destination: .recents)
                ForEach(Array(store.recents.prefix(3).enumerated()), id: \.element.id) { index, recent in
                    if let section = data.section(recent.sectionId) {
                        if index > 0 { LexHairline() }
                        NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
                            SectionRowView(
                                number: section.number,
                                title: section.title,
                                subtitle: data.act(section.actId)?.displayShortName
                            )
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
            }
        }
    }

    // MARK: Saved & notes

    private var savedBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockHeader(LexStrings.t("myspace.saved", store.language), destination: .notes)
            if store.saved.isEmpty {
                hintRow(
                    symbol: "bookmark",
                    text: LexStrings.t("myspace.hint.saved", store.language)
                )
            } else {
                ForEach(Array(store.saved.prefix(3).enumerated()), id: \.element.id) { index, item in
                    if let section = data.section(item.sectionId) {
                        if index > 0 { LexHairline() }
                        NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
                            SectionRowView(
                                number: section.number,
                                title: section.title,
                                subtitle: item.note.isEmpty ? data.act(section.actId)?.displayShortName : item.note
                            )
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
            }
        }
    }

    // MARK: My downloads

    private var downloadsBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockHeader(LexStrings.t("myspace.downloads", store.language), destination: .downloads)
            if store.downloads.isEmpty {
                NavigationLink(value: Destination.documents) {
                    hintRow(
                        symbol: "arrow.down.circle",
                        text: LexStrings.t("myspace.hint.downloads", store.language)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(LexPressStyle())
            } else {
                ForEach(Array(store.downloads.prefix(3).enumerated()), id: \.element.id) { index, record in
                    if let document = DocumentCatalog.document(record.documentId) {
                        if index > 0 { LexHairline() }
                        NavigationLink(value: Destination.document(document.id)) {
                            downloadRow(document, record: record)
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
            }
        }
    }

    private func downloadRow(_ document: LexDocument, record: DownloadRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: document.kind.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.brandSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(LexLocalize.docTitle(document, store.language))
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(1)
                Text("\(document.kind.groupTitle(store.language)) · \(LexLocalize.date(record.date, store.language))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: Shared bits

    private func blockHeader(_ title: String, destination: Destination) -> some View {
        HStack {
            LexOverline(text: title)
            Spacer()
            NavigationLink(value: destination) {
                Text(LexStrings.t("common.seeAll", store.language))
                    .font(LexFont.sans(13, .medium))
                    .foregroundStyle(LexColor.brand)
            }
        }
        .padding(.bottom, 4)
    }

    private func hintRow(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.slate)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.surface))
            Text(text)
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}
