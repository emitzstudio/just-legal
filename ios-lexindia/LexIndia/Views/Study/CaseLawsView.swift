//
//  CaseLawsView.swift
//  LexIndia
//
//  Landmark judgments with principles, summaries and linked provisions.
//

import SwiftUI

struct CaseLawsView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @State private var query: String = ""

    private var filtered: [CaseLaw] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = data.core.caseLaws.sorted { $0.year > $1.year }
        guard !q.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.lowercased().contains(q) || $0.principle.lowercased().contains(q)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("account.caseLaws", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("cases.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                searchField
                    .padding(.top, 14)

                if filtered.isEmpty {
                    LexEmptyState(
                        symbol: "text.quote",
                        title: LexStrings.t("cases.emptyTitle", store.language),
                        message: LexStrings.t("cases.emptySub", store.language)
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, caseLaw in
                            if index > 0 { LexHairline() }
                            NavigationLink(value: Destination.caseLaw(caseLaw.id)) {
                                CaseLawRow(caseLaw: caseLaw)
                            }
                            .buttonStyle(LexPressStyle())
                        }
                    }
                    .padding(.top, 6)
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.slate)
            TextField(LexStrings.t("cases.search", store.language), text: $query)
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

struct CaseLawDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let caseLawId: String

    var body: some View {
        if let caseLaw = data.caseLaw(caseLawId) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center) {
                            LexOverline(text: LexStrings.t("cases.one", store.language), color: LexColor.saffronDeep)
                            Spacer()
                            ReadAloudControl(
                                id: caseLaw.id,
                                text: "\(caseLaw.title). \(caseLaw.court), \(caseLaw.year). Key principle: \(caseLaw.principle). \(caseLaw.summary)"
                            )
                        }
                        Text(caseLaw.title)
                            .font(LexFont.display(25, .bold))
                            .foregroundStyle(LexColor.ink)
                            .lineSpacing(2)
                        Text("\(caseLaw.court) · \(String(caseLaw.year))")
                            .font(LexFont.sans(13))
                            .foregroundStyle(LexColor.slate)
                    }
                    .padding(.top, 8)

                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .fill(LexColor.saffron)
                            .frame(width: 4)
                        VStack(alignment: .leading, spacing: 8) {
                            LexOverline(text: LexStrings.t("cases.principle", store.language), color: LexColor.saffronDeep)
                            Text(caseLaw.principle)
                                .font(LexFont.display(17, .semibold))
                                .foregroundStyle(LexColor.ink)
                                .lineSpacing(4)
                                .lexTranslatable(caseLaw.principle)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(LexColor.surface)
                    .clipShape(.rect(cornerRadius: 4))
                    .padding(.top, 22)

                    LexOverline(text: LexStrings.t("cases.summary", store.language))
                        .padding(.top, 24)
                    Text(caseLaw.summary)
                        .font(LexFont.sans(15))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(6)
                        .padding(.top, 8)
                        .lexTranslatable(caseLaw.summary)

                    let related = caseLaw.relatedSectionIds.compactMap { data.section($0) }
                    if !related.isEmpty {
                        LexOverline(text: LexStrings.t("cases.related", store.language))
                            .padding(.top, 26)
                        VStack(spacing: 0) {
                            ForEach(Array(related.enumerated()), id: \.element.id) { index, section in
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

                    Text(LexStrings.t("cases.note", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 24)
                        .padding(.bottom, 26)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        } else {
            LexEmptyState(
                symbol: "text.quote",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("cases.notFound", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }
}
