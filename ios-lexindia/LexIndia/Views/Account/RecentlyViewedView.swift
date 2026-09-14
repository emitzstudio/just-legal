//
//  RecentlyViewedView.swift
//  LexIndia
//
//  The reading trail.
//

import SwiftUI

struct RecentlyViewedView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if store.recents.isEmpty {
                    LexEmptyState(
                        symbol: "clock",
                        title: LexStrings.t("updates.empty", store.language),
                        message: LexStrings.t("recents.emptySub", store.language)
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.recents.enumerated()), id: \.element.id) { index, recent in
                            if let section = data.section(recent.sectionId) {
                                if index > 0 { LexHairline() }
                                NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
                                    SectionRowView(
                                        number: section.number,
                                        title: section.title,
                                        subtitle: "\(data.act(section.actId)?.displayShortName ?? "") · \(LexLocalize.dateTime(recent.date, store.language))"
                                    )
                                }
                                .buttonStyle(LexPressStyle())
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationTitle(LexStrings.t("account.recents", store.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.recents.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LexStrings.t("common.clear", store.language)) {
                        store.clearRecents()
                    }
                    .font(LexFont.sans(14, .medium))
                    .foregroundStyle(LexColor.brand)
                }
            }
        }
    }
}
