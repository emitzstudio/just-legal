//
//  DefinitionsView.swift
//  LexIndia
//
//  Glossary of legal terms: browse, search, open, save.
//

import SwiftUI

struct DefinitionsView: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("account.definitions", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("defs.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                DefinitionsBrowser(embedded: false)
                    .padding(.top, 14)

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Reusable glossary list used by the Definitions screen and the Library tab.
struct DefinitionsBrowser: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    let embedded: Bool

    @State private var query: String = ""
    @State private var selected: LegalDefinition?
    @State private var pushTarget: ReaderTarget?

    private var filtered: [LegalDefinition] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = data.core.definitions.sorted { $0.term.lowercased() < $1.term.lowercased() }
        guard !q.isEmpty else { return sorted }
        return sorted.filter {
            $0.term.lowercased().contains(q) || $0.meaning.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            if filtered.isEmpty {
                LexEmptyState(
                    symbol: "character.book.closed",
                    title: LexStrings.t("defs.emptyTitle", store.language),
                    message: LexStrings.t("defs.emptySub", store.language)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, definition in
                        if index > 0 { LexHairline() }
                        Button {
                            selected = definition
                        } label: {
                            HStack(alignment: .center, spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(definition.term)
                                        .font(LexFont.display(16, .semibold))
                                        .foregroundStyle(LexColor.ink)
                                        .multilineTextAlignment(.leading)
                                    Text(definition.meaning)
                                        .font(LexFont.sans(13))
                                        .foregroundStyle(LexColor.slate)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 8)
                                if store.isDefinitionSaved(definition.id) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(LexColor.saffronDeep)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(LexColor.faint)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
                .padding(.top, 6)
            }
        }
        .sheet(item: $selected) { definition in
            DefinitionDetailSheet(definition: definition) { sectionId in
                selected = nil
                if let section = data.section(sectionId) {
                    Task {
                        try? await Task.sleep(for: .milliseconds(380))
                        pushTarget = ReaderTarget(actId: section.actId, sectionId: section.id)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(LexColor.surface)
        }
        .navigationDestination(item: $pushTarget) { target in
            SectionReaderView(actId: target.actId, startSectionId: target.sectionId)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.slate)
            TextField(LexStrings.t("defs.search", store.language), text: $query)
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.ink)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(LexColor.faint)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(LexColor.hairline, lineWidth: 1)
        )
    }
}

/// Full definition with source note, related provisions and save.
struct DefinitionDetailSheet: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    let definition: LegalDefinition
    let onOpenSection: (String) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        LexOverline(text: LexStrings.t("defs.one", store.language), color: LexColor.saffronDeep)
                        Text(definition.term)
                            .font(LexFont.display(24, .bold))
                            .foregroundStyle(LexColor.ink)
                    }
                    Spacer()
                    saveButton
                }
                .padding(.top, 22)

                Text(definition.meaning)
                    .font(LexFont.sans(16))
                    .foregroundStyle(LexColor.ink)
                    .lineSpacing(6)
                    .padding(.top, 14)

                if let source = definition.sourceNote {
                    Text(source)
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                        .padding(.top, 10)
                }

                let related = definition.relatedSectionIds.compactMap { data.section($0) }
                if !related.isEmpty {
                    LexOverline(text: LexStrings.t("cases.related", store.language))
                        .padding(.top, 24)
                    VStack(spacing: 0) {
                        ForEach(Array(related.enumerated()), id: \.element.id) { index, section in
                            if index > 0 { LexHairline() }
                            Button {
                                onOpenSection(section.id)
                            } label: {
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

                let cases = definition.relatedCaseLawIds.compactMap { data.caseLaw($0) }
                if !cases.isEmpty {
                    LexOverline(text: LexStrings.t("cases.one", store.language))
                        .padding(.top, 20)
                    ForEach(cases) { caseLaw in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(caseLaw.title)
                                .font(LexFont.display(15, .semibold))
                                .foregroundStyle(LexColor.ink)
                            Text("\(caseLaw.court) · \(String(caseLaw.year))")
                                .font(LexFont.sans(12))
                                .foregroundStyle(LexColor.slate)
                            Text(caseLaw.principle)
                                .font(LexFont.sans(13))
                                .foregroundStyle(LexColor.slate)
                                .lineSpacing(3)
                        }
                        .padding(.vertical, 10)
                    }
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.surface)
    }

    private var saveButton: some View {
        let saved = store.isDefinitionSaved(definition.id)
        return Button {
            store.toggleSavedDefinition(definition.id)
        } label: {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(saved ? LexColor.saffronDeep : LexColor.slate)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .sensoryFeedback(.success, trigger: saved)
        .accessibilityLabel(saved ? "Remove saved term" : "Save term")
    }
}
