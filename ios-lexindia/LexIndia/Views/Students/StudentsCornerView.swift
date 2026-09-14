//
//  StudentsCornerView.swift
//  LexIndia
//
//  The student hub: quizzes with the weekly reward, downloadable study
//  resources, study tools, and the roadmap (courses, competitions, moot
//  courts) clearly marked as coming soon.
//

import SwiftUI

struct StudentsCornerView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    private let resourceKinds: [DocumentKind] = [.examNote, .previousPaper, .revision]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 14)

                quizHero
                    .padding(.top, 20)

                ForEach(resourceKinds) { kind in
                    resourceGroup(kind)
                        .padding(.top, 26)
                }

                toolsBlock
                    .padding(.top, 26)

                comingSoonBlock
                    .padding(.top, 28)

                TrustFootnote()
                    .padding(.vertical, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LexStrings.t("students.title", store.language))
                    .font(LexFont.display(34, .bold))
                    .foregroundStyle(LexColor.ink)
                Text(LexStrings.t("students.subtitle", store.language))
                    .font(LexFont.sans(15))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer()
            LexSearchButton()
        }
    }

    // MARK: Quiz hero

    private var quizHero: some View {
        NavigationLink(value: Destination.quizzes) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    LexOverline(
                        text: LexStrings.t("students.quizzes", store.language),
                        color: LexColor.onBrand.opacity(0.62)
                    )
                    Spacer()
                    weeklyChip
                }
                Text(LexStrings.t("quiz.title", store.language))
                    .font(LexFont.display(23, .bold))
                    .foregroundStyle(LexColor.onBrand)
                Text(LexStrings.t("students.quiz.sub", store.language))
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.onBrand.opacity(0.78))
                HStack(spacing: 5) {
                    Text(LexStrings.t("students.quiz.cta", store.language))
                        .font(LexFont.sans(14, .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(LexColor.onBrand)
                .padding(.top, 2)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [LexColor.brand, LexColor.brandDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(.rect(cornerRadius: 20))
            .overlay(alignment: .bottomTrailing) {
                ScalesGlyph()
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(LexColor.onBrand.opacity(0.16))
                    .frame(width: 92, height: 92)
                    .padding(.trailing, 10)
                    .padding(.bottom, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Quiz Challenge. \(weeklyChipText)")
    }

    /// Streak-aware chip: shows perfect-score progress while the streak
    /// builds, the gift once it's complete, the seal after claiming.
    private var weeklyChipText: String {
        if !store.isWeeklyQuizRewardAvailable {
            return LexStrings.t("quiz.weekly.claimed", store.language)
        }
        if store.isRewardStreakComplete {
            return LexStrings.t("quiz.weekly.available", store.language)
        }
        return LexStrings.f("quiz.streak.chip", store.language, store.quizPerfectStreak, QuizConfig.streakTarget)
    }

    private var weeklyChip: some View {
        let claimed = !store.isWeeklyQuizRewardAvailable
        return HStack(spacing: 5) {
            Image(systemName: claimed ? "checkmark.seal" : (store.isRewardStreakComplete ? "gift" : "flame"))
                .font(.system(size: 9, weight: .bold))
            Text(weeklyChipText)
                .font(LexFont.sans(10, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(claimed ? LexColor.slate : LexColor.saffronDeep)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(LexColor.onBrand.opacity(0.92)))
    }

    // MARK: Resources

    private func resourceGroup(_ kind: DocumentKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                LexOverline(text: kind.groupTitle(store.language))
                Text(kind.groupBlurb(store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            VStack(spacing: 0) {
                ForEach(Array(DocumentCatalog.documents(of: kind).enumerated()), id: \.element.id) { index, document in
                    if index > 0 { LexHairline().padding(.leading, 62) }
                    NavigationLink(value: Destination.document(document.id)) {
                        DocumentRow(document: document, isDownloaded: store.isDownloaded(document.id))
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: Tools

    private var toolsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: LexStrings.t("students.tools", store.language))
            HStack(spacing: 8) {
                toolChip(LexStrings.t("account.definitions", store.language), symbol: "character.book.closed", destination: .definitions)
                toolChip(LexStrings.t("account.caseLaws", store.language), symbol: "text.quote", destination: .caseLaws)
                toolChip("IPC → BNS", symbol: "arrow.left.arrow.right", destination: .ipcBns)
            }
        }
    }

    private func toolChip(_ title: String, symbol: String, destination: Destination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(LexFont.sans(12, .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

    // MARK: Coming soon

    private var comingSoonBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: LexStrings.t("students.coming", store.language))
            VStack(spacing: 0) {
                comingRow(symbol: "book.closed", titleKey: "students.courses", subKey: "students.courses.sub", index: 0)
                LexHairline().padding(.leading, 62)
                comingRow(symbol: "medal", titleKey: "students.competitions", subKey: "students.competitions.sub", index: 2)
                LexHairline().padding(.leading, 62)
                comingRow(symbol: "person.2.wave.2", titleKey: "students.moot", subKey: "students.moot.sub", index: 5)
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }

    private func comingRow(symbol: String, titleKey: String, subKey: String, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.pastel(index).tone)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.pastel(index).fill))
            VStack(alignment: .leading, spacing: 2) {
                Text(LexStrings.t(titleKey, store.language))
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.ink)
                Text(LexStrings.t(subKey, store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer(minLength: 8)
            Text(LexStrings.t("common.comingSoon", store.language))
                .font(LexFont.sans(10, .semibold))
                .foregroundStyle(LexColor.slate)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LexColor.canvas))
                .overlay(Capsule().strokeBorder(LexColor.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}
