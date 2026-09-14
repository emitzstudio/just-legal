//
//  ChapterSectionsView.swift
//  LexIndia
//
//  Chapter → its sections, highly scannable.
//

import SwiftUI

struct ChapterSectionsView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    let chapterId: String

    var body: some View {
        if let chapter = data.chapter(chapterId),
           let actId = data.actId(forChapter: chapterId),
           let act = data.act(actId) {
            let sections = data.sections(inChapter: chapterId)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        LexOverline(text: "\(LexStrings.t("reader.chapter", store.language)) \(chapter.numeral)", color: LexColor.saffronDeep)
                        Text(LexLocalize.chapterTitle(numeral: chapter.numeral, fallback: chapter.title, actId: actId, store.language))
                            .font(LexFont.display(25, .bold))
                            .foregroundStyle(LexColor.ink)
                        Text("\(LexLocalize.actName(act, store.language)) · \(chapter.rangeLabel)")
                            .font(LexFont.sans(13))
                            .foregroundStyle(LexColor.slate)
                    }
                    .padding(.top, 8)

                    BenchDivider()
                        .padding(.vertical, 18)

                    VStack(spacing: 0) {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            if index > 0 { LexHairline() }
                            NavigationLink(value: Destination.reader(actId: actId, sectionId: section.id)) {
                                SectionRowView(
                                    number: section.number,
                                    title: section.title,
                                    subtitle: section.ipcLabel.map { "\(LexStrings.t("understand.earlier", store.language)) \($0)" },
                                    showsGuideBadge: section.hasGuide
                                )
                            }
                            .buttonStyle(LexPressStyle())
                        }
                    }

                    footnote(sections: sections)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
            .background(LexColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        } else {
            fallbackEmpty
        }
    }

    private func footnote(sections: [LegalSection]) -> some View {
        let guides = sections.filter(\.hasGuide).count
        let text = guides > 0
            ? LexStrings.f("chapter.foot.some", store.language, sections.count, guides)
            : LexStrings.f("chapter.foot.none", store.language, sections.count)
        return Text(text)
            .font(LexFont.sans(12))
            .italic()
            .foregroundStyle(LexColor.slate)
    }

    private var fallbackEmpty: some View {
        LexEmptyState(
            symbol: "book.closed",
            title: LexStrings.t("act.notFound.title", store.language),
            message: LexStrings.t("chapter.notFound", store.language)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LexColor.canvas.ignoresSafeArea())
    }
}
