//
//  LibraryView.swift
//  LexIndia
//
//  The Law Library — the main content and discovery hub of LexIndia:
//  Laws & Acts, Study material, Legal Updates, Documents, areas of law,
//  real-life situations and popular topics.
//

import SwiftUI

struct LibraryView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    /// Major codes first, then the other Acts.
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

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LexStrings.t("library.title", store.language))
                            .font(LexFont.display(34, .bold))
                            .foregroundStyle(LexColor.ink)
                        Text(LexStrings.t("library.subtitle", store.language))
                            .font(LexFont.sans(15))
                            .foregroundStyle(LexColor.slate)
                    }
                    Spacer()
                    LexSearchButton()
                }
                .padding(.top, 14)

                LexOverline(text: LexStrings.t("library.lawsActs", store.language))
                    .padding(.top, 20)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(orderedActs.enumerated()), id: \.element.id) { index, act in
                        lawTile(act, index: index)
                    }
                }
                .padding(.top, 10)

                ipcConverterTile
                    .padding(.top, 12)

                studyBlock
                    .padding(.top, 28)

                updatesBlock
                    .padding(.top, 28)

                documentsBlock
                    .padding(.top, 28)

                areasBlock
                    .padding(.top, 28)

                situationsBlock
                    .padding(.top, 28)

                topicsBlock
                    .padding(.top, 28)

                TrustFootnote()
                    .padding(.vertical, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Law tiles

    private func lawTile(_ act: LegalAct, index: Int) -> some View {
        let loaded = data.sections(inAct: act.id)
        let pastel = LexColor.pastel(index)
        return NavigationLink(value: Destination.act(act.id)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(String(act.displayShortName.prefix(1)))
                        .font(LexFont.display(16, .bold))
                        .foregroundStyle(pastel.tone)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.frost(0.62, dark: 0.14)))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(pastel.tone.opacity(0.55))
                }
                Text(act.displayShortName)
                    .font(LexFont.display(19, .bold))
                    .foregroundStyle(pastel.tone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 12)
                Text(LexLocalize.actName(act, store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(pastel.tone.opacity(0.78))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)
                statusLine(act, tone: pastel.tone, loaded: loaded.count, guided: loaded.filter(\.hasGuide).count)
                    .padding(.top, 9)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(pastel.fill)
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(LexLocalize.actName(act, store.language)). \(loaded.isEmpty ? LexStrings.t("prepared.title", store.language) : "\(loaded.count) \(LexStrings.t("library.badge.sections", store.language))")")
    }

    @ViewBuilder
    private func statusLine(_ act: LegalAct, tone: Color, loaded: Int, guided: Int) -> some View {
        if loaded > 0 {
            Text(act.id == "bns"
                ? "\(LexStrings.t("library.badge.fulltext", store.language)) · \(loaded) §§ · \(LexStrings.t("library.badge.ipcmap", store.language))"
                : "\(guided > 0 ? "\(guided) \(LexStrings.t("library.badge.guided", store.language))" : "\(loaded) \(LexStrings.t("library.badge.sections", store.language))")")
                .font(LexFont.sans(11, .semibold))
                .foregroundStyle(tone)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LexColor.frost(0.65, dark: 0.16)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            Text(LexStrings.t("prepared.badge", store.language))
                .font(LexFont.sans(11, .semibold))
                .foregroundStyle(tone.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LexColor.frost(0.5, dark: 0.10)))
        }
    }

    private var ipcConverterTile: some View {
        NavigationLink(value: Destination.ipcBns) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LexColor.onBrand))
                VStack(alignment: .leading, spacing: 2) {
                    Text("IPC → BNS")
                        .font(LexFont.display(17, .semibold))
                        .foregroundStyle(LexColor.brand)
                    Text(LexStrings.t("library.ipc.sub", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.brandSoft)
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("IPC to BNS converter")
    }

    // MARK: Study material

    private var studyBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("library.study", store.language))
            NavigationLink(value: Destination.studyMaterial) {
                wideCard(
                    pastel: LexColor.pastel(2),
                    symbol: "graduationcap",
                    title: LexStrings.t("library.student.title", store.language),
                    subtitle: LexStrings.t("library.student.sub", store.language),
                    footnote: LexStrings.t("library.student.foot", store.language)
                )
            }
            .buttonStyle(LexPressStyle())
            HStack(spacing: 8) {
                toolChip(LexStrings.t("account.definitions", store.language), symbol: "character.book.closed", destination: .definitions)
                toolChip(LexStrings.t("account.caseLaws", store.language), symbol: "text.quote", destination: .caseLaws)
            }
        }
    }

    // MARK: Legal updates

    private var updatesBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                LexOverline(text: LexStrings.t("library.updates", store.language))
                Spacer()
                NavigationLink(value: Destination.legalUpdates) {
                    Text(LexStrings.t("library.allUpdates", store.language))
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.brand)
                }
            }
            .padding(.bottom, 10)
            VStack(spacing: 10) {
                ForEach(LegalUpdatesCatalog.updates.prefix(2)) { update in
                    NavigationLink(value: Destination.legalUpdate(update.id)) {
                        updatePreviewCard(update)
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    private func updatePreviewCard(_ update: LegalUpdate) -> some View {
        let pastel = LexColor.pastel(update.category.pastelIndex)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(update.category.label(store.language))
                    .font(LexFont.sans(11, .semibold))
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
                .font(LexFont.display(16, .semibold))
                .foregroundStyle(LexColor.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(LexLocalize.updateSnippet(update, store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
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

    // MARK: Documents

    private var documentsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("library.documents", store.language))
            NavigationLink(value: Destination.documents) {
                wideCard(
                    pastel: LexColor.pastel(7),
                    symbol: "doc.text",
                    title: LexStrings.t("library.documentsForms", store.language),
                    subtitle: LexStrings.t("library.documents.sub", store.language),
                    footnote: LexStrings.t("library.documents.foot", store.language)
                )
            }
            .buttonStyle(LexPressStyle())
        }
    }

    // MARK: Areas of law

    private var areasBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("library.browseArea", store.language))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(data.core.categories.enumerated()), id: \.element.id) { index, category in
                        NavigationLink(value: Destination.category(category.id)) {
                            Text(LexLocalize.categoryName(category, store.language))
                                .font(LexFont.sans(14, .medium))
                                .foregroundStyle(LexColor.pastel(index).tone)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(LexColor.pastel(index).fill))
                        }
                        .buttonStyle(LexPressStyle())
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Situations

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
            }
        }
    }

    // MARK: Topics

    private var topicsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("library.topics", store.language))
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

    // MARK: Shared cards

    private func wideCard(pastel: (fill: Color, tone: Color), symbol: String, title: String, subtitle: String, footnote: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(pastel.tone)
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LexColor.frost(0.62, dark: 0.14)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LexFont.display(18, .bold))
                        .foregroundStyle(pastel.tone)
                    Text(subtitle)
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(pastel.tone.opacity(0.82))
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(pastel.tone.opacity(0.6))
            }
            Text(footnote)
                .font(LexFont.sans(11, .semibold))
                .foregroundStyle(pastel.tone)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LexColor.frost(0.65, dark: 0.16)))
                .padding(.top, 12)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pastel.fill)
        .clipShape(.rect(cornerRadius: 16))
        .contentShape(Rectangle())
    }

    private func toolChip(_ title: String, symbol: String, destination: Destination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(LexFont.sans(13, .semibold))
            }
            .foregroundStyle(LexColor.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(LexColor.brandSoft)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }
}
