//
//  ActDetailView.swift
//  LexIndia
//
//  Act → its chapters, as a structured table of contents,
//  with search within the Act.
//

import SwiftUI

struct ActDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let actId: String
    @State private var filter: String = ""

    var body: some View {
        if let act = data.act(actId) {
            let loadedSections = data.sections(inAct: actId)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header(act, loaded: loadedSections.count, guided: loadedSections.filter(\.hasGuide).count)

                    if act.id == "bns" {
                        ipcShortcut
                            .padding(.top, 16)
                    }

                    if !loadedSections.isEmpty {
                        filterField
                            .padding(.top, 16)
                    }

                    if !filter.trimmingCharacters(in: .whitespaces).isEmpty {
                        filteredResults(act, sections: loadedSections)
                            .padding(.top, 12)
                    } else if act.chapters.isEmpty {
                        PreparedPanel(message: LexStrings.t("prepared.message", store.language))
                            .padding(.top, 22)
                    } else {
                        chaptersBlock(act)
                            .padding(.top, 22)
                    }

                    Text("\(LexStrings.t("act.source", store.language)): \(LexLocalize.actSource(act, store.language)) · \(LexLocalize.actEffective(act, store.language))")
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 26)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationTitle(act.displayShortName)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            LexEmptyState(
                symbol: "book.closed",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("act.notFound.act", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }

    private func header(_ act: LegalAct, loaded: Int, guided: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LexOverline(text: LexLocalize.actSource(act, store.language), color: LexColor.saffronDeep)
            Text(LexLocalize.actName(act, store.language))
                .font(LexFont.display(26, .bold))
                .foregroundStyle(LexColor.ink)
            Text(LexLocalize.actSummary(act, store.language))
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(4)
            FlowLayout(spacing: 8) {
                if loaded > 0 {
                    infoChip("\(LexStrings.t("library.badge.fulltext", store.language)) · \(loaded) \(LexStrings.t("library.badge.sections", store.language))", tone: LexColor.mintDeep, fill: LexColor.mint)
                } else {
                    infoChip(LexStrings.t("prepared.title", store.language), tone: LexColor.saffronDeep, fill: LexColor.saffronSoft)
                }
                if guided > 0 {
                    infoChip("\(guided) \(LexStrings.t("library.badge.guided", store.language))", tone: LexColor.brand, fill: LexColor.brandSoft)
                }
                infoChip(LexLocalize.actEffective(act, store.language))
            }
            .padding(.top, 6)
        }
        .padding(.top, 8)
    }

    private func infoChip(_ text: String, tone: Color = LexColor.slate, fill: Color = LexColor.surface) -> some View {
        Text(text)
            .font(LexFont.sans(12, .medium))
            .foregroundStyle(tone)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(fill))
            .overlay(
                Capsule().strokeBorder(fill == LexColor.surface ? LexColor.hairline : Color.clear, lineWidth: 1)
            )
    }

    /// Familiar entry point for readers who know the old IPC numbers.
    private var ipcShortcut: some View {
        NavigationLink(value: Destination.ipcBns) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.onBrand))
                VStack(alignment: .leading, spacing: 2) {
                    Text(LexStrings.t("act.ipcCard.title", store.language))
                        .font(LexFont.display(15, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("act.ipcCard.sub", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.brandSoft)
            .clipShape(.rect(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("IPC to BNS converter")
    }

    private var filterField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.slate)
            TextField(LexStrings.t("act.searchIn", store.language), text: $filter)
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.ink)
                .autocorrectionDisabled()
            if !filter.isEmpty {
                Button {
                    filter = ""
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

    @ViewBuilder
    private func filteredResults(_ act: LegalAct, sections: [LegalSection]) -> some View {
        let query = filter.trimmingCharacters(in: .whitespaces).lowercased()
        let matches = sections.filter {
            $0.number.lowercased().hasPrefix(query)
                || $0.title.lowercased().contains(query)
                || $0.keywords.contains(where: { $0.contains(query) })
        }
        if matches.isEmpty {
            LexEmptyState(
                symbol: "magnifyingglass",
                title: LexStrings.t("act.noMatches", store.language),
                message: LexStrings.t("act.noMatches.sub", store.language)
            )
        } else {
            VStack(spacing: 0) {
                ForEach(Array(matches.prefix(30).enumerated()), id: \.element.id) { index, section in
                    if index > 0 { LexHairline() }
                    NavigationLink(value: Destination.reader(actId: act.id, sectionId: section.id)) {
                        SectionRowView(number: section.number, title: section.title, showsGuideBadge: section.hasGuide)
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    private func chaptersBlock(_ act: LegalAct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LexOverline(text: LexStrings.t("act.contents", store.language))
                .padding(.bottom, 4)
            ForEach(Array(act.chapters.enumerated()), id: \.element.id) { index, chapter in
                let chapterSections = data.sections(inChapter: chapter.id)
                if index > 0 { LexHairline() }
                if !chapterSections.isEmpty {
                    NavigationLink(value: Destination.chapter(chapter.id)) {
                        chapterRow(chapter, count: chapterSections.count, guides: chapterSections.filter(\.hasGuide).count)
                    }
                    .buttonStyle(LexPressStyle())
                } else {
                    chapterRow(chapter, count: 0, guides: 0)
                        .opacity(0.62)
                }
            }
        }
    }

    private func chapterRow(_ chapter: LegalChapter, count: Int, guides: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                LexOverline(text: "\(LexStrings.t("reader.chapter", store.language)) \(chapter.numeral)", color: LexColor.saffronDeep)
                Text(LexLocalize.chapterTitle(numeral: chapter.numeral, fallback: chapter.title, actId: actId, store.language))
                    .font(LexFont.display(17, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                Text(chapterSubtitle(chapter, count: count, guides: guides))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer(minLength: 8)
            if count > 0 {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LexColor.brand)
            }
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    private func chapterSubtitle(_ chapter: LegalChapter, count: Int, guides: Int) -> String {
        let language = store.language
        guard count > 0 else { return "\(chapter.rangeLabel) · \(LexStrings.t("act.beingPrepared", language))" }
        let sectionsWord = language == .hindi
            ? LexStrings.t("library.badge.sections", language)
            : (count == 1 ? "section" : "sections")
        var line = "\(chapter.rangeLabel) · \(count) \(sectionsWord)"
        if guides > 0 {
            line += " · \(guides) \(LexStrings.t("library.badge.guided", language))"
        }
        return line
    }
}
