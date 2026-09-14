//
//  UnderstandMoreSheet.swift
//  LexIndia
//
//  Contextual depth for the current section in two tabs:
//  Understand More (example, key points, terms, related, old-code
//  reference) and Landmark Cases (only cases linked to this section).
//

import SwiftUI

struct UnderstandMoreSheet: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let section: LegalSection
    let onOpenSection: (String) -> Void

    private enum SheetTab: String, CaseIterable, Identifiable {
        case understand = "Understand more"
        case cases = "Landmark cases"

        var id: String { rawValue }
    }

    @State private var tab: SheetTab = .understand
    @State private var expandedCaseId: String?
    @State private var expandedDefinitionId: String?

    /// Cases linked to this specific section (direct links plus cases that
    /// reference the section), in stable order without duplicates.
    private var linkedCases: [CaseLaw] {
        var seen = Set<String>()
        var result: [CaseLaw] = []
        for id in section.caseLawIds {
            if let caseLaw = data.caseLaw(id), seen.insert(caseLaw.id).inserted {
                result.append(caseLaw)
            }
        }
        for caseLaw in data.core.caseLaws where caseLaw.relatedSectionIds.contains(section.id) {
            if seen.insert(caseLaw.id).inserted {
                result.append(caseLaw)
            }
        }
        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        LexOverline(text: "\(LexStrings.t("reader.section", store.language)) \(section.number)", color: LexColor.saffronDeep)
                        Text(section.title)
                            .font(LexFont.display(20, .semibold))
                            .foregroundStyle(LexColor.ink)
                    }
                    Spacer()
                    LexCloseButton()
                }
                .padding(.top, 20)

                Picker("Content", selection: $tab) {
                    ForEach(SheetTab.allCases) { tab in
                        Text(LexStrings.t(tab == .understand ? "reader.understand" : "reader.cases", store.language)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 16)

                Group {
                    switch tab {
                    case .understand:
                        understandContent
                    case .cases:
                        casesContent
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: tab)

                Text(LexStrings.t("trust.footnote", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .padding(.top, 26)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.surface)
    }

    // MARK: Understand more

    @ViewBuilder
    private var understandContent: some View {
        if !section.hasGuide && section.example == nil && section.keyPoints.isEmpty && section.relatedSectionIds.isEmpty {
            LexEmptyState(
                symbol: "text.book.closed",
                title: "Guide being prepared",
                message: "The plain-language guide for Section \(section.number) — example, key points and related sections — is being prepared for LexIndia. The full official text is on the reading page."
            )
            .padding(.top, 12)
        }

        if let example = section.example {
            block(title: LexStrings.t("understand.example", store.language)) {
                Text(example)
                    .font(LexFont.sans(15))
                    .foregroundStyle(LexColor.ink)
                    .lineSpacing(5)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LexColor.saffronSoft)
                    .clipShape(.rect(cornerRadius: 12))
                    .lexTranslatable(example)
            }
        }

        if !section.keyPoints.isEmpty {
            block(title: LexStrings.t("understand.keypoints", store.language)) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(section.keyPoints, id: \.self) { point in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(LexColor.mintDeep)
                            Text(point)
                                .font(LexFont.sans(15))
                                .foregroundStyle(LexColor.ink)
                                .lineSpacing(4)
                        }
                    }
                }
            }
        }

        if let ipcLabel = section.ipcLabel {
            block(title: LexStrings.t("understand.oldcode", store.language)) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LexColor.saffronDeep)
                        Text("\(LexStrings.t("understand.earlier", store.language)) \(ipcLabel)")
                            .font(LexFont.sans(14, .semibold))
                            .foregroundStyle(LexColor.ink)
                    }
                    if let note = data.core.ipcMappings.first(where: { $0.sectionId == section.id })?.note {
                        Text(note)
                            .font(LexFont.sans(13))
                            .foregroundStyle(LexColor.slate)
                            .lineSpacing(3)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LexColor.blueSoft)
                .clipShape(.rect(cornerRadius: 12))
            }
        }

        let related = section.relatedSectionIds.compactMap { data.section($0) }
        if !related.isEmpty {
            block(title: LexStrings.t("understand.relatedSections", store.language)) {
                VStack(spacing: 0) {
                    ForEach(Array(related.enumerated()), id: \.element.id) { index, relatedSection in
                        if index > 0 { LexHairline() }
                        Button {
                            onOpenSection(relatedSection.id)
                        } label: {
                            SectionRowView(
                                number: relatedSection.number,
                                title: relatedSection.title,
                                subtitle: relatedSection.actId == section.actId
                                    ? nil
                                    : data.act(relatedSection.actId)?.displayShortName
                            )
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
            }
        }

        let definitions = section.definitionIds.compactMap { data.definition($0) }
        if !definitions.isEmpty {
            block(title: LexStrings.t("understand.definitions", store.language)) {
                VStack(spacing: 0) {
                    ForEach(Array(definitions.enumerated()), id: \.element.id) { index, definition in
                        if index > 0 { LexHairline() }
                        definitionRow(definition)
                    }
                }
            }
        }
    }

    // MARK: Landmark cases

    @ViewBuilder
    private var casesContent: some View {
        let cases = linkedCases
        if cases.isEmpty {
            LexEmptyState(
                symbol: "text.quote",
                title: "No landmark cases yet",
                message: "No cases are linked to Section \(section.number) in LexIndia yet. They appear here as the case library grows."
            )
            .padding(.top, 12)
        } else {
            block(title: cases.count == 1 ? LexStrings.t("understand.casesOne", store.language) : LexStrings.f("understand.casesMany", store.language, cases.count)) {
                VStack(spacing: 0) {
                    ForEach(Array(cases.enumerated()), id: \.element.id) { index, caseLaw in
                        if index > 0 { LexHairline() }
                        caseRow(caseLaw)
                    }
                }
            }
        }
    }

    // MARK: Building blocks

    private func block(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            LexOverline(text: title)
            content()
        }
        .padding(.top, 24)
    }

    private func caseRow(_ caseLaw: CaseLaw) -> some View {
        let expanded = expandedCaseId == caseLaw.id
        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                expandedCaseId = expanded ? nil : caseLaw.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(caseLaw.title)
                        .font(LexFont.display(16, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LexColor.slate)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                Text("\(caseLaw.court) · \(String(caseLaw.year))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                Text(caseLaw.principle)
                    .font(LexFont.sans(14))
                    .foregroundStyle(LexColor.ink)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                if expanded {
                    Text(caseLaw.summary)
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityHint(expanded ? "Collapses the case summary" : "Expands the case summary")
    }

    private func definitionRow(_ definition: LegalDefinition) -> some View {
        let expanded = expandedDefinitionId == definition.id
        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                expandedDefinitionId = expanded ? nil : definition.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(definition.term)
                        .font(LexFont.display(16, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LexColor.slate)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                if expanded {
                    Text(definition.meaning)
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                    if let source = definition.sourceNote {
                        Text(source)
                            .font(LexFont.sans(12))
                            .foregroundStyle(LexColor.saffronDeep)
                    }
                } else {
                    Text(definition.meaning)
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }
}
