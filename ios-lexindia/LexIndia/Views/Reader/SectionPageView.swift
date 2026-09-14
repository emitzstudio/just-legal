//
//  SectionPageView.swift
//  LexIndia
//
//  One legal provision as a quiet reading page: official text,
//  unmistakably distinct plain-language panel, previous/next controls.
//

import SwiftUI

struct SectionPageView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let section: LegalSection
    let onNavigate: (String) -> Void
    let onToggleSave: () -> Void

    private var act: LegalAct? { data.act(section.actId) }

    /// What Read Aloud speaks for this page.
    private var spokenText: String {
        var parts: [String] = ["Section \(section.number). \(section.title)."]
        if section.hasOfficialText, let text = section.officialText {
            parts.append(text)
        }
        parts.append("In simple words: \(section.explanation)")
        return parts.joined(separator: " ")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                BenchDivider()
                    .padding(.vertical, 20)
                officialBlock
                simpleWordsBlock
                    .padding(.top, 24)
                pagerRow
                    .padding(.top, 26)
                sourceFootnote
                    .padding(.top, 22)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                LexOverline(text: LexStrings.t("reader.section", store.language), color: LexColor.saffronDeep)
                Spacer()
                ReadAloudControl(id: section.id, text: spokenText)
                bookmarkButton
            }
            .padding(.top, 6)
            HStack(alignment: .center, spacing: 12) {
                Text(section.number)
                    .font(LexFont.statute(54, .bold).monospacedDigit())
                    .foregroundStyle(LexColor.brand)
                if let ipc = ipcChipLabel {
                    lineageChip(ipc: ipc)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
            Text(section.title)
                .font(LexFont.display(26, .bold))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(2)
                .padding(.top, 4)
            if let act {
                Text(LexLocalize.actName(act, store.language))
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.brand)
                    .padding(.top, 8)
            }
            if let chapter = data.chapter(section.chapterId) {
                Text(LexLocalize.chapterLine(numeral: chapter.numeral, title: chapter.title, actId: section.actId, store.language))
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                    .padding(.top, 3)
            }
        }
    }

    /// IPC label trimmed of parenthetical notes, e.g. "IPC 6–52 (consolidated)" → "IPC 6–52".
    private var ipcChipLabel: String? {
        guard let raw = section.ipcLabel else { return nil }
        guard let parenthesis = raw.firstIndex(of: "(") else { return raw }
        let trimmed = raw[..<parenthesis].trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? raw : trimmed
    }

    private func lineageChip(ipc: String) -> some View {
        let code = act?.displayShortName ?? "BNS"
        return HStack(spacing: 7) {
            Text(ipc)
                .font(LexFont.sans(13, .semibold).monospacedDigit())
                .foregroundStyle(LexColor.saffronDeep)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(LexColor.saffronDeep.opacity(0.7))
            Text("\(code) \(section.number)")
                .font(LexFont.sans(13, .semibold).monospacedDigit())
                .foregroundStyle(LexColor.brand)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(LexColor.saffronSoft))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Earlier \(ipc), now \(code) \(section.number)")
    }

    private var bookmarkButton: some View {
        let saved = store.isSaved(section.id)
        return Button(action: onToggleSave) {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(saved ? LexColor.saffronDeep : LexColor.slate)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .symbolEffect(.bounce, options: .nonRepeating, isActive: saved && !reduceMotion)
        .sensoryFeedback(.success, trigger: saved)
        .accessibilityLabel(saved ? "Remove bookmark" : "Save section")
    }

    // MARK: Official text

    /// The statute itself reads on warm parchment — paper inside the night library.
    @ViewBuilder
    private var officialBlock: some View {
        if section.hasOfficialText, let text = section.officialText {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    LexOverline(text: LexStrings.t("reader.official", store.language), color: LexColor.onPaper.opacity(0.55))
                    Spacer()
                    AccentDiamond(size: 5)
                }
                Text(text)
                    .font(LexFont.statute(17))
                    .foregroundStyle(LexColor.onPaper)
                    .lineSpacing(7)
                if let note = section.textNote {
                    Text(note)
                        .font(LexFont.sans(12))
                        .italic()
                        .foregroundStyle(LexColor.onPaper.opacity(0.66))
                        .lineSpacing(3)
                        .padding(.top, 2)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.paper)
            .clipShape(.rect(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                LexOverline(text: LexStrings.t("reader.official", store.language))
                PreparedPanel(message: section.textNote ?? "The official text of this section is being prepared for LexIndia. Refer to the official Gazette until then.")
            }
        }
    }

    // MARK: In simple words

    /// Curated sections get the confident blue guide panel; sections whose
    /// guide is still being written get a quiet, clearly-marked variant.
    @ViewBuilder
    private var simpleWordsBlock: some View {
        if section.hasGuide {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(LexColor.brand)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 9) {
                    LexOverline(text: LexStrings.t("reader.simple", store.language), color: LexColor.brand)
                    Text(section.explanation)
                        .font(LexFont.sans(16))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(6)
                        .lexTranslatable(section.explanation)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(LexColor.blueSoft)
            .clipShape(.rect(cornerRadius: 12))
        } else {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(LexColor.saffron.opacity(0.6))
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 9) {
                    LexOverline(text: LexStrings.t("reader.simple", store.language), color: LexColor.saffronDeep)
                    Text(section.explanation)
                        .font(LexFont.sans(15))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(5)
                        .lexTranslatable(section.explanation)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: Previous / next

    private var pagerRow: some View {
        let neighbors = data.neighbors(of: section)
        return VStack(spacing: 10) {
            LexHairline()
            HStack {
                if let previous = neighbors.previous {
                    Button {
                        onNavigate(previous.id)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(LexStrings.t("reader.sAbbrev", store.language)) \(previous.number)")
                                .font(LexFont.sans(15, .semibold).monospacedDigit())
                        }
                        .foregroundStyle(LexColor.brand)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                    .accessibilityLabel("Previous, Section \(previous.number), \(previous.title)")
                } else {
                    Color.clear.frame(width: 60, height: 32)
                }
                Spacer()
                Text(LexStrings.t("reader.swipe", store.language))
                    .font(LexFont.sans(11))
                    .foregroundStyle(LexColor.slate)
                Spacer()
                if let next = neighbors.next {
                    Button {
                        onNavigate(next.id)
                    } label: {
                        HStack(spacing: 5) {
                            Text("\(LexStrings.t("reader.sAbbrev", store.language)) \(next.number)")
                                .font(LexFont.sans(15, .semibold).monospacedDigit())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(LexColor.brand)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LexPressStyle())
                    .accessibilityLabel("Next, Section \(next.number), \(next.title)")
                } else {
                    Color.clear.frame(width: 60, height: 32)
                }
            }
            LexHairline()
        }
    }

    private var sourceFootnote: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let act {
                Text("\(LexStrings.t("act.source", store.language)): \(LexLocalize.actName(act, store.language)) — \(LexLocalize.actSource(act, store.language)) · \(LexLocalize.actEffective(act, store.language))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Text(LexStrings.t("trust.footnote", store.language))
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
        }
    }
}
