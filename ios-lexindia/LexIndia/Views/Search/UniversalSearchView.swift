//
//  UniversalSearchView.swift
//  LexIndia
//
//  Universal search over the whole product, presented above the current
//  screen. Results are grouped by source (Law Library, Documents,
//  Students Corner, Legal Updates, My Space, Settings); closing returns
//  the user exactly where they were.
//

import SwiftUI

struct UniversalSearchView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui

    @State private var query: String = ""
    @State private var path: [Destination] = []
    @State private var selectedDefinition: LegalDefinition?
    @FocusState private var focused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    if trimmedQuery.isEmpty {
                        idleContent
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                    } else {
                        resultsContent
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                    }
                }
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .lexDestinations()
        }
        .tint(LexColor.brand)
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            focused = true
        }
        .sheet(item: $selectedDefinition) { definition in
            DefinitionDetailSheet(definition: definition) { sectionId in
                selectedDefinition = nil
                store.recordSearch(trimmedQuery)
                if let section = data.section(sectionId) {
                    path.append(.reader(actId: section.actId, sectionId: section.id))
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(LexColor.surface)
        }
    }

    private func close() {
        ui.searchPresented = false
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(LexStrings.t("search.title", store.language))
                    .font(LexFont.display(26, .bold))
                    .foregroundStyle(LexColor.ink)
                Spacer()
                LexCloseButton(action: close)
            }
            searchBar
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.slate)
            TextField(LexStrings.t("search.placeholder", store.language), text: $query)
                .font(LexFont.sans(16))
                .foregroundStyle(LexColor.ink)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit {
                    store.recordSearch(trimmedQuery)
                }
            if !query.isEmpty {
                Button {
                    query = ""
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(LexColor.faint)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(focused ? LexColor.brand : LexColor.hairline, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.15), value: focused)
    }

    // MARK: Idle

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !store.recentSearches.isEmpty {
                HStack {
                    LexOverline(text: LexStrings.t("search.recent", store.language))
                    Spacer()
                    Button(LexStrings.t("common.clear", store.language)) {
                        store.clearSearches()
                    }
                    .font(LexFont.sans(13, .medium))
                    .foregroundStyle(LexColor.brand)
                }
                .padding(.bottom, 2)
                ForEach(store.recentSearches, id: \.self) { recent in
                    Button {
                        query = recent
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: "clock")
                                .font(.system(size: 13))
                                .foregroundStyle(LexColor.slate)
                            Text(recent)
                                .font(LexFont.sans(15))
                                .foregroundStyle(LexColor.ink)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LexColor.faint)
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                }
                Spacer().frame(height: 24)
            }

            LexOverline(text: LexStrings.t("search.popular", store.language))
                .padding(.bottom, 12)
            FlowLayout(spacing: 8) {
                ForEach(data.core.popularSearches, id: \.self) { term in
                    Button {
                        query = term
                    } label: {
                        Text(term)
                            .font(LexFont.sans(14, .medium))
                            .foregroundStyle(LexColor.ink)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(LexColor.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(LexColor.hairline, lineWidth: 1))
                    }
                    .buttonStyle(LexPressStyle())
                }
            }

            Text(LexStrings.t("search.hint", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(4)
                .padding(.top, 28)
                .padding(.bottom, 24)
        }
    }

    // MARK: Results

    @ViewBuilder
    private var resultsContent: some View {
        let results = data.globalSearch(trimmedQuery, store: store)
        if results.isEmpty {
            LexEmptyState(
                symbol: "magnifyingglass",
                title: LexStrings.t("search.noResults", store.language),
                message: LexStrings.t("search.noResults.sub", store.language)
            )
            .padding(.top, 30)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                libraryGroup(results)
                ipcGroup(results)
                termsGroup(results)
                casesGroup(results)
                documentsGroup(results)
                studentsGroup(results)
                updatesGroup(results)
                mySpaceGroup(results)
                settingsGroup(results)
                Spacer().frame(height: 30)
            }
        }
    }

    private func group(_ titleKey: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            LexOverline(text: LexStrings.t(titleKey, store.language), color: LexColor.saffronDeep)
                .padding(.top, 22)
            content()
        }
    }

    // MARK: Law Library

    @ViewBuilder
    private func libraryGroup(_ results: GlobalSearchResults) -> some View {
        if !results.core.acts.isEmpty || !results.core.sections.isEmpty || !results.core.topics.isEmpty {
            group("search.group.library") {
                ForEach(results.core.acts) { act in
                    NavigationLink(value: Destination.act(act.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(act.name)
                                .font(LexFont.display(16, .semibold))
                                .foregroundStyle(LexColor.ink)
                            Text(act.extentLabel)
                                .font(LexFont.sans(13))
                                .foregroundStyle(LexColor.slate)
                        }
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                    .simultaneousGesture(TapGesture().onEnded { store.recordSearch(trimmedQuery) })
                    LexHairline()
                }
                ForEach(Array(results.core.sections.enumerated()), id: \.element.id) { index, hit in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.reader(actId: hit.section.actId, sectionId: hit.section.id)) {
                        sectionHitRow(hit)
                    }
                    .buttonStyle(LexPressStyle())
                    .simultaneousGesture(TapGesture().onEnded { store.recordSearch(trimmedQuery) })
                }
                ForEach(results.core.topics) { topic in
                    LexHairline()
                    NavigationLink(value: Destination.topic(topic.id)) {
                        HStack(spacing: 12) {
                            Image(systemName: "tag")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LexColor.brand)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.name)
                                    .font(LexFont.display(16, .semibold))
                                    .foregroundStyle(LexColor.ink)
                                Text("\(topic.sectionIds.count) \(LexStrings.t("search.linkedSections", store.language))")
                                    .font(LexFont.sans(13))
                                    .foregroundStyle(LexColor.slate)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(LexColor.faint)
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    private func sectionHitRow(_ hit: SectionHit) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(hit.section.number)
                .font(LexFont.display(20, .semibold).monospacedDigit())
                .foregroundStyle(LexColor.brand)
                .frame(minWidth: 46, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(hit.section.title)
                    .font(LexFont.sans(16, .medium))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                Text(data.act(hit.section.actId)?.name ?? "")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                if let reason = hit.reason {
                    Text(reason)
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: IPC → BNS

    @ViewBuilder
    private func ipcGroup(_ results: GlobalSearchResults) -> some View {
        if !results.core.mappings.isEmpty {
            group("search.group.ipc") {
                ForEach(Array(results.core.mappings.enumerated()), id: \.element.id) { index, mapping in
                    if index > 0 { LexHairline() }
                    mappingRow(mapping)
                }
            }
        }
    }

    @ViewBuilder
    private func mappingRow(_ mapping: IPCMapping) -> some View {
        if let sectionId = mapping.sectionId, let section = data.section(sectionId) {
            NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
                mappingRowContent(mapping, openable: true)
            }
            .buttonStyle(LexPressStyle())
            .simultaneousGesture(TapGesture().onEnded { store.recordSearch(trimmedQuery) })
        } else {
            mappingRowContent(mapping, openable: false)
        }
    }

    private func mappingRowContent(_ mapping: IPCMapping, openable: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("IPC \(mapping.ipc)")
                        .font(LexFont.sans(15, .semibold).monospacedDigit())
                        .foregroundStyle(LexColor.ink)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LexColor.saffronDeep)
                    Text("BNS \(mapping.bnsLabel)")
                        .font(LexFont.sans(15, .semibold).monospacedDigit())
                        .foregroundStyle(LexColor.brand)
                }
                Text(mapping.ipcTitle)
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            if openable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LexColor.faint)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: Terms & cases

    @ViewBuilder
    private func termsGroup(_ results: GlobalSearchResults) -> some View {
        if !results.core.definitions.isEmpty {
            group("search.group.terms") {
                ForEach(Array(results.core.definitions.enumerated()), id: \.element.id) { index, definition in
                    if index > 0 { LexHairline() }
                    Button {
                        selectedDefinition = definition
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(definition.term)
                                .font(LexFont.display(16, .semibold))
                                .foregroundStyle(LexColor.ink)
                            Text(definition.meaning)
                                .font(LexFont.sans(13))
                                .foregroundStyle(LexColor.slate)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func casesGroup(_ results: GlobalSearchResults) -> some View {
        if !results.core.caseLaws.isEmpty {
            group("search.group.cases") {
                ForEach(Array(results.core.caseLaws.enumerated()), id: \.element.id) { index, caseLaw in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.caseLaw(caseLaw.id)) {
                        CaseLawRow(caseLaw: caseLaw)
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    // MARK: Documents & students

    @ViewBuilder
    private func documentsGroup(_ results: GlobalSearchResults) -> some View {
        if !results.documents.isEmpty {
            group("search.group.documents") {
                ForEach(Array(results.documents.enumerated()), id: \.element.id) { index, document in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.document(document.id)) {
                        DocumentRow(document: document, isDownloaded: store.isDownloaded(document.id))
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func studentsGroup(_ results: GlobalSearchResults) -> some View {
        if !results.studentDocs.isEmpty || results.quizzesMatch {
            group("search.group.students") {
                if results.quizzesMatch {
                    Button {
                        ui.openQuizzes()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(LexColor.brand)
                                .frame(width: 36, height: 36)
                                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.brandSoft))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LexStrings.t("quiz.title", store.language))
                                    .font(LexFont.sans(15, .medium))
                                    .foregroundStyle(LexColor.ink)
                                Text(LexStrings.t("students.quiz.sub", store.language))
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
                    .buttonStyle(LexPressStyle())
                    if !results.studentDocs.isEmpty { LexHairline() }
                }
                ForEach(Array(results.studentDocs.enumerated()), id: \.element.id) { index, document in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.document(document.id)) {
                        DocumentRow(document: document, isDownloaded: store.isDownloaded(document.id))
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    // MARK: Updates, My Space & settings

    @ViewBuilder
    private func updatesGroup(_ results: GlobalSearchResults) -> some View {
        if !results.updates.isEmpty {
            group("search.group.updates") {
                ForEach(Array(results.updates.enumerated()), id: \.element.id) { index, update in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.legalUpdate(update.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(LexLocalize.updateTitle(update, store.language))
                                .font(LexFont.sans(15, .medium))
                                .foregroundStyle(LexColor.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text("\(update.category.label(store.language)) · \(LexLocalize.updateDate(update, store.language))")
                                .font(LexFont.sans(12))
                                .foregroundStyle(LexColor.slate)
                        }
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func mySpaceGroup(_ results: GlobalSearchResults) -> some View {
        if !results.savedSections.isEmpty {
            group("search.group.myspace") {
                ForEach(Array(results.savedSections.enumerated()), id: \.element.id) { index, section in
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

    @ViewBuilder
    private func settingsGroup(_ results: GlobalSearchResults) -> some View {
        if !results.settings.isEmpty {
            group("search.group.settings") {
                ForEach(Array(results.settings.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 { LexHairline() }
                    settingsRow(entry)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsRow(_ entry: SettingsSearchEntry) -> some View {
        if let destination = entry.destination {
            NavigationLink(value: destination) {
                settingsRowContent(entry)
            }
            .buttonStyle(LexPressStyle())
        } else {
            Button {
                close()
                ui.plansPresented = true
            } label: {
                settingsRowContent(entry)
            }
            .buttonStyle(LexPressStyle())
        }
    }

    private func settingsRowContent(_ entry: SettingsSearchEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 24)
            Text(LexStrings.t(entry.titleKey, store.language))
                .font(LexFont.sans(15, .medium))
                .foregroundStyle(LexColor.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
