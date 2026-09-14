//
//  QuizSetupView.swift
//  LexIndia
//
//  Configure a quiz: pick one or more topics, choose 20/50/100 questions,
//  see the perfect-score streak toward the weekly reward, start. Reward
//  amounts and the streak target come from QuizConfig — never hard-coded
//  here.
//

import SwiftUI

struct QuizSetupView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    @State private var selectedTopics: Set<QuizTopic> = [.bns, .ipcBns]
    @State private var selectedCount: Int = 20
    @State private var deck: [QuizQuestion] = []
    @State private var isPlaying: Bool = false

    var body: some View {
        let poolCount = QuizEngine.pool(for: selectedTopics, data: data).count
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("quiz.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("quiz.subtitle", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                weeklyBanner
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 2) {
                    LexOverline(text: LexStrings.t("quiz.topics", store.language))
                    Text(LexStrings.t("quiz.topics.hint", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 24)

                FlowLayout(spacing: 8) {
                    ForEach(QuizTopic.allCases) { topic in
                        topicChip(topic)
                    }
                }
                .padding(.top, 10)

                LexOverline(text: LexStrings.t("quiz.length", store.language))
                    .padding(.top, 26)

                HStack(spacing: 10) {
                    ForEach(QuizConfig.lengths) { rule in
                        lengthCard(rule, poolCount: poolCount)
                    }
                }
                .padding(.top, 10)

                Text("\(min(poolCount, 999)) \(LexStrings.t("quiz.available", store.language))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .padding(.top, 10)

                if selectedTopics.isEmpty {
                    hint(LexStrings.t("quiz.needTopics", store.language))
                        .padding(.top, 12)
                } else if poolCount < selectedCount {
                    hint(LexStrings.t("quiz.pool.short", store.language))
                        .padding(.top, 12)
                }

                Button {
                    startQuiz()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(LexStrings.t("quiz.start", store.language))
                    }
                }
                .buttonStyle(LexPrimaryButtonStyle())
                .disabled(selectedTopics.isEmpty || poolCount < selectedCount)
                .opacity(selectedTopics.isEmpty || poolCount < selectedCount ? 0.45 : 1)
                .padding(.top, 18)

                Text(LexStrings.t("quiz.weekly.rule", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPlaying) {
            QuizPlayView(questions: deck)
        }
    }

    // MARK: Streak & weekly reward

    private var weeklyBanner: some View {
        let claimed = !store.isWeeklyQuizRewardAvailable
        let complete = store.isRewardStreakComplete
        let iconName = claimed ? "checkmark.seal" : (complete ? "gift" : "flame")
        let iconTone: Color = claimed ? LexColor.slate : (complete ? LexColor.mintDeep : LexColor.saffronDeep)
        let iconFill: Color = claimed ? LexColor.canvas : (complete ? LexColor.mint : LexColor.saffronSoft)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconTone)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 11).fill(iconFill))
                VStack(alignment: .leading, spacing: 2) {
                    Text(LexStrings.t("quiz.streak.title", store.language))
                        .font(LexFont.sans(14, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.f("quiz.streak.progress", store.language, store.quizPerfectStreak, QuizConfig.streakTarget))
                        .font(LexFont.sans(12).monospacedDigit())
                        .foregroundStyle(LexColor.slate)
                }
                Spacer(minLength: 0)
            }
            QuizStreakMeter(streak: store.quizPerfectStreak)
            Text(streakBannerMessage)
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
            Text(rewardSummary)
                .font(LexFont.sans(11).monospacedDigit())
                .foregroundStyle(LexColor.slate)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(complete && !claimed ? LexColor.mintDeep.opacity(0.35) : LexColor.hairline, lineWidth: 1)
        )
    }

    private var streakBannerMessage: String {
        let language = store.language
        if !store.isWeeklyQuizRewardAvailable {
            return LexStrings.t(store.isRewardStreakComplete ? "quiz.streak.complete" : "quiz.weekly.claimed", language)
        }
        if store.isRewardStreakComplete {
            return LexStrings.t("quiz.streak.ready", language)
        }
        let left = QuizConfig.streakTarget - store.quizPerfectStreak
        return left == 1
            ? LexStrings.t("quiz.streak.one", language)
            : LexStrings.f("quiz.streak.need", language, left)
    }

    private var rewardSummary: String {
        QuizConfig.lengths
            .map { "\($0.questionCount) → +\($0.credits)" }
            .joined(separator: " · ")
    }

    // MARK: Topic chips

    private func topicChip(_ topic: QuizTopic) -> some View {
        let isSelected = selectedTopics.contains(topic)
        let pastel = LexColor.pastel(topic.pastelIndex)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                if isSelected {
                    selectedTopics.remove(topic)
                } else {
                    selectedTopics.insert(topic)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark" : topic.symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(topic.label(store.language))
                    .font(LexFont.sans(13, .semibold))
            }
            .foregroundStyle(isSelected ? pastel.tone : LexColor.slate)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Capsule().fill(isSelected ? pastel.fill : LexColor.surface))
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : LexColor.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(topic.label(store.language))\(isSelected ? ", selected" : "")")
    }

    // MARK: Length cards

    private func lengthCard(_ rule: QuizRewardRule, poolCount: Int) -> some View {
        let isSelected = selectedCount == rule.questionCount
        let isAvailable = poolCount >= rule.questionCount
        return Button {
            selectedCount = rule.questionCount
        } label: {
            VStack(spacing: 4) {
                Text("\(rule.questionCount)")
                    .font(LexFont.display(24, .bold).monospacedDigit())
                    .foregroundStyle(isSelected ? LexColor.brand : LexColor.ink)
                Text("+\(rule.credits) \(LexStrings.t("quiz.reward.per", store.language))")
                    .font(LexFont.sans(11, .semibold))
                    .foregroundStyle(isSelected ? LexColor.saffronDeep : LexColor.slate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? LexColor.brand : LexColor.hairline, lineWidth: isSelected ? 1.6 : 1)
            )
            .opacity(isAvailable ? 1 : 0.4)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .disabled(!isAvailable)
        .accessibilityLabel("\(rule.questionCount) questions, reward \(rule.credits) credits\(isSelected ? ", selected" : "")")
    }

    private func hint(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LexColor.saffronDeep)
            Text(text)
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 12))
    }

    private func startQuiz() {
        let questions = QuizEngine.makeQuiz(topics: selectedTopics, count: selectedCount, data: data)
        guard questions.count == selectedCount else { return }
        deck = questions
        isPlaying = true
    }
}

/// Segment meter for the perfect-score streak — shared by the quiz setup
/// banner and the result screen.
struct QuizStreakMeter: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<QuizConfig.streakTarget, id: \.self) { step in
                Capsule()
                    .fill(step < streak ? LexColor.saffronDeep : LexColor.hairline)
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(duration: 0.4), value: streak)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) of \(QuizConfig.streakTarget) perfect scores")
    }
}
