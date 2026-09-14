//
//  CategoryDetailView.swift
//  LexIndia
//
//  Category → the Acts it contains.
//

import SwiftUI

struct CategoryDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let categoryId: String

    var body: some View {
        if let category = data.category(categoryId) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LexLocalize.categoryName(category, store.language))
                            .font(LexFont.display(30, .bold))
                            .foregroundStyle(LexColor.ink)
                        Text(LexLocalize.categoryTagline(category, store.language))
                            .font(LexFont.sans(15))
                            .foregroundStyle(LexColor.slate)
                    }
                    .padding(.top, 8)

                    BenchDivider()
                        .padding(.vertical, 20)

                    VStack(spacing: 0) {
                        ForEach(Array(data.acts(inCategory: categoryId).enumerated()), id: \.element.id) { index, act in
                            if index > 0 { LexHairline() }
                            NavigationLink(value: Destination.act(act.id)) {
                                actRow(act)
                            }
                            .buttonStyle(LexPressStyle())
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
                symbol: "books.vertical",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("act.notFound.category", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }

    private func actRow(_ act: LegalAct) -> some View {
        let guided = data.sections(inAct: act.id).count
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LexLocalize.actName(act, store.language))
                    .font(LexFont.display(19, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                Text("\(LexLocalize.actExtent(act, store.language)) · \(LexLocalize.actEffective(act, store.language))")
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                if guided > 0 {
                    Text("\(guided) \(LexStrings.t("act.guidedSections", store.language))")
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.brand)
                } else {
                    Text(LexStrings.t("prepared.title", store.language))
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LexColor.brand)
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}
