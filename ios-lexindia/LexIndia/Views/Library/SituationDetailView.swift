//
//  SituationDetailView.swift
//  LexIndia
//
//  A real-life situation as a discovery path into the legal dataset.
//

import SwiftUI

struct SituationDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let situationId: String

    var body: some View {
        if let situation = data.situation(situationId) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: situation.symbol)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(LexColor.saffronDeep)
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LexColor.saffronSoft)
                            )
                        Text(LexLocalize.situationTitle(situation, store.language))
                            .font(LexFont.display(30, .bold))
                            .foregroundStyle(LexColor.ink)
                        Text(situation.intro)
                            .font(LexFont.sans(15))
                            .foregroundStyle(LexColor.slate)
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)

                    BenchDivider()
                        .padding(.vertical, 22)

                    LexOverline(text: LexStrings.t("situation.relevant", store.language))
                    VStack(spacing: 0) {
                        ForEach(Array(situation.sectionIds.enumerated()), id: \.element) { index, sectionId in
                            if let section = data.section(sectionId) {
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

                    if !situation.definitionIds.isEmpty {
                        LexOverline(text: LexStrings.t("situation.terms", store.language))
                            .padding(.top, 26)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(situation.definitionIds.enumerated()), id: \.element) { index, definitionId in
                                if let definition = data.definition(definitionId) {
                                    if index > 0 { LexHairline() }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(definition.term)
                                            .font(LexFont.display(16, .semibold))
                                            .foregroundStyle(LexColor.ink)
                                        Text(definition.meaning)
                                            .font(LexFont.sans(14))
                                            .foregroundStyle(LexColor.slate)
                                            .lineSpacing(3)
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }

                    Text(LexStrings.t("situation.note", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        } else {
            LexEmptyState(
                symbol: "questionmark.circle",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("situation.notFound", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }
}

/// Popular-topic screen: a curated list of sections for one topic.
struct TopicSectionsView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let topicId: String

    var body: some View {
        if let topic = data.topic(topicId) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(LexLocalize.topicName(topic, store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                        .padding(.top, 8)
                    Text(LexStrings.t("situation.provisions", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 4)

                    BenchDivider()
                        .padding(.vertical, 20)

                    VStack(spacing: 0) {
                        ForEach(Array(topic.sectionIds.enumerated()), id: \.element) { index, sectionId in
                            if let section = data.section(sectionId) {
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
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        } else {
            LexEmptyState(
                symbol: "questionmark.circle",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("topic.notFound", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }
}
