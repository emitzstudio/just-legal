//
//  LegalUpdatesView.swift
//  LexIndia
//
//  Legal Updates — court news, new laws, amendments and notifications.
//  Currently demo content; the production pipeline is editorial:
//  Source → Review → LexIndia summary → Publish. Nothing is scraped.
//

import SwiftUI

struct LegalUpdatesView: View {
    @Environment(UserDataStore.self) private var store

    @State private var selectedCategory: UpdateCategory?

    private var filtered: [LegalUpdate] {
        LegalUpdatesCatalog.updates(in: selectedCategory)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("updates.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("updates.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                previewNotice
                    .padding(.top, 14)

                categoryChips
                    .padding(.top, 14)

                VStack(spacing: 10) {
                    ForEach(filtered) { update in
                        NavigationLink(value: Destination.legalUpdate(update.id)) {
                            updateCard(update)
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
                .padding(.top, 16)

                if filtered.isEmpty {
                    LexEmptyState(
                        symbol: "newspaper",
                        title: LexStrings.t("updates.empty", store.language),
                        message: LexStrings.t("updates.empty.sub", store.language)
                    )
                }

                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.18), value: filtered.count)
    }

    private var previewNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LexColor.saffronDeep)
                .padding(.top, 1)
            Text(LexStrings.t("updates.preview", store.language))
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, label: LexStrings.t("common.all", store.language))
                ForEach(UpdateCategory.allCases) { category in
                    filterChip(category, label: category.label(store.language))
                }
            }
        }
        .scrollClipDisabled()
    }

    private func filterChip(_ category: UpdateCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.easeOut(duration: 0.16)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(LexFont.sans(13, .semibold))
                .foregroundStyle(isSelected ? LexColor.onBrand : LexColor.slate)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? LexColor.brand : LexColor.surface))
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : LexColor.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(label)\(isSelected ? ", selected" : "")")
    }

    private func updateCard(_ update: LegalUpdate) -> some View {
        let pastel = LexColor.pastel(update.category.pastelIndex)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: update.category.symbol)
                        .font(.system(size: 10, weight: .semibold))
                    Text(update.category.label(store.language))
                        .font(LexFont.sans(11, .semibold))
                }
                .foregroundStyle(pastel.tone)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(pastel.fill))
                Spacer()
                Text(LexLocalize.updateDate(update, store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Text(LexLocalize.updateTitle(update, store.language))
                .font(LexFont.display(17, .semibold))
                .foregroundStyle(LexColor.ink)
                .multilineTextAlignment(.leading)
            Text(LexLocalize.updateSnippet(update, store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                Text(LexStrings.t("updates.read", store.language))
                    .font(LexFont.sans(13, .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(LexColor.brand)
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
}

// MARK: - Update detail

struct LegalUpdateDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let updateId: String

    var body: some View {
        if let update = LegalUpdatesCatalog.update(updateId) {
            let pastel = LexColor.pastel(update.category.pastelIndex)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: update.category.symbol)
                                .font(.system(size: 10, weight: .semibold))
                            Text(update.category.label(store.language))
                                .font(LexFont.sans(11, .semibold))
                        }
                        .foregroundStyle(pastel.tone)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(pastel.fill))
                        Spacer()
                        ReadAloudControl(
                            id: update.id,
                            text: "\(update.title). \(update.body.joined(separator: " "))"
                        )
                    }
                    .padding(.top, 10)

                    Text(LexLocalize.updateTitle(update, store.language))
                        .font(LexFont.display(25, .bold))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(2)
                        .padding(.top, 12)

                    Text("\(LexLocalize.updateSource(update, store.language)) · \(LexLocalize.updateDate(update, store.language))")
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 6)

                    BenchDivider()
                        .padding(.vertical, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(update.body.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(LexFont.sans(15))
                                .foregroundStyle(LexColor.ink)
                                .lineSpacing(5)
                                .lexTranslatable(paragraph)
                        }
                    }

                    relatedBlock(update)

                    demoFootnote
                        .padding(.top, 24)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        } else {
            LexEmptyState(
                symbol: "newspaper",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("updates.notFound", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func relatedBlock(_ update: LegalUpdate) -> some View {
        let sections = update.relatedSectionIds.compactMap { data.section($0) }
        if !sections.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                LexOverline(text: LexStrings.t("updates.provisions", store.language))
                    .padding(.top, 24)
                    .padding(.bottom, 4)
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
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

    private var demoFootnote: some View {
        VStack(alignment: .leading, spacing: 8) {
            LexOverline(text: LexStrings.t("updates.previewShort", store.language), color: LexColor.saffronDeep)
            Text(LexStrings.t("updates.demo.note", store.language))
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 12))
    }
}
