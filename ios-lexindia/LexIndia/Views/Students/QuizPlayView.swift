//
//  QuizPlayView.swift
//  LexIndia
//
//  The timed quiz flow: one question at a time with instant feedback and a
//  live countdown (one minute per question). Finishing opens a full study
//  review — score, stats, the perfect-score streak toward the weekly
//  reward, and every question with the user's answer beside the correct
//  one. Reward rules live in QuizConfig, never hard-coded here.
//

import SwiftUI

struct QuizPlayView: View {
    @Environment(UserDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let questions: [QuizQuestion]

    @State private var deck: [QuizQuestion] = []
    @State private var index: Int = 0
    @State private var chosen: Int?
    /// The chosen option per question, aligned with `deck`. `nil` means the
    /// question was never answered (only possible when time runs out).
    @State private var answers: [Int?] = []
    @State private var isFinished: Bool = false
    @State private var confirmExit: Bool = false
    @State private var claimedCredits: Int?
    @State private var streakAtResult: Int = 0
    @State private var correctTick: Int = 0
    @State private var wrongTick: Int = 0
    @State private var lowTimeTick: Int = 0
    @State private var ringProgress: Double = 0

    // Countdown
    @State private var endDate: Date = .distantFuture
    @State private var remaining: Int = 0
    @State private var remainingAtFinish: Int = 0
    @State private var timedOut: Bool = false

    var body: some View {
        ZStack {
            LexColor.canvas.ignoresSafeArea()
            if isFinished {
                resultView
            } else {
                playView
            }
        }
        .sensoryFeedback(.success, trigger: correctTick)
        .sensoryFeedback(.error, trigger: wrongTick)
        .sensoryFeedback(.warning, trigger: lowTimeTick)
        .alert(LexStrings.t("quiz.exit.title", store.language), isPresented: $confirmExit) {
            Button(LexStrings.t("quiz.exit.confirm", store.language), role: .destructive) {
                dismiss()
            }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        } message: {
            Text(LexStrings.t("quiz.exit.message", store.language))
        }
        .task { await runCountdown() }
    }

    private var current: QuizQuestion? {
        deck.indices.contains(index) ? deck[index] : nil
    }

    private var timeLimit: Int {
        QuizConfig.timeLimit(questionCount: deck.count)
    }

    /// Single source of truth for the score — derived from the answer sheet.
    private var correctCount: Int {
        zip(deck, answers).reduce(0) { total, pair in
            total + (pair.0.answerIndex == pair.1 ? 1 : 0)
        }
    }

    // MARK: Countdown

    /// Sets the quiz up and drives the countdown for the whole session.
    /// The deadline is a fixed date, so ticks stay accurate across question
    /// navigation and short suspensions; the task dies with the view.
    private func runCountdown() async {
        if deck.isEmpty {
            deck = questions
            answers = Array(repeating: nil, count: questions.count)
        }
        if endDate == .distantFuture {
            endDate = Date().addingTimeInterval(TimeInterval(timeLimit))
            remaining = timeLimit
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(200))
            guard !isFinished else { continue }
            let left = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
            if left != remaining {
                remaining = left
                if left == 60 || left == 10 {
                    lowTimeTick += 1
                }
            }
            if left == 0 {
                finish(timedOut: true)
            }
        }
    }

    private static func timeString(_ seconds: Int) -> String {
        "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    private var timerBadge: some View {
        let isLow = remaining <= 60
        let isCritical = remaining <= 10
        let tone: Color = isCritical ? LexColor.pastel(4).tone : (isLow ? LexColor.saffronDeep : LexColor.ink)
        let fill: Color = isCritical ? LexColor.pastel(4).fill : (isLow ? LexColor.saffronSoft : LexColor.surface)
        return HStack(spacing: 5) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
            Text(Self.timeString(remaining))
                .font(LexFont.sans(13, .bold).monospacedDigit())
                .contentTransition(.numericText(countsDown: true))
        }
        .foregroundStyle(tone)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(fill))
        .overlay(
            Capsule().strokeBorder(isLow ? Color.clear : LexColor.hairline, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.25), value: isLow)
        .animation(.easeOut(duration: 0.25), value: isCritical)
        .accessibilityLabel("\(LexStrings.t("quiz.time.left", store.language)): \(Self.timeString(remaining))")
    }

    // MARK: Play

    private var playView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                LexCloseButton { confirmExit = true }
                Spacer()
                Text("\(index + 1) / \(deck.count)")
                    .font(LexFont.sans(14, .semibold).monospacedDigit())
                    .foregroundStyle(LexColor.ink)
                Spacer()
                timerBadge
            }
            .padding(.top, 14)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(LexColor.hairline)
                    Capsule()
                        .fill(LexColor.brand)
                        .frame(width: geo.size.width * CGFloat(index + (chosen == nil ? 0 : 1)) / CGFloat(max(deck.count, 1)))
                        .animation(.spring(duration: 0.4), value: index)
                        .animation(.spring(duration: 0.4), value: chosen != nil)
                }
            }
            .frame(height: 5)
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if let current {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                LexOverline(text: "\(LexStrings.t("quiz.question", store.language)) \(index + 1)", color: LexColor.saffronDeep)
                                Spacer(minLength: 8)
                                Text(current.topic.label(store.language))
                                    .font(LexFont.sans(10, .semibold))
                                    .foregroundStyle(LexColor.pastel(current.topic.pastelIndex).tone)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(LexColor.pastel(current.topic.pastelIndex).fill))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: 150, alignment: .trailing)
                            }
                            Text(current.prompt)
                                .font(LexFont.display(20, .semibold))
                                .foregroundStyle(LexColor.ink)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LexColor.surface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(LexColor.hairline, lineWidth: 1)
                        )

                        VStack(spacing: 10) {
                            ForEach(Array(current.options.enumerated()), id: \.offset) { optionIndex, option in
                                optionButton(optionIndex, option: option, question: current)
                            }
                        }
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .padding(.horizontal, 22)
    }

    private func optionButton(_ optionIndex: Int, option: String, question: QuizQuestion) -> some View {
        let letters = ["A", "B", "C", "D", "E"]
        let isAnswer = optionIndex == question.answerIndex
        let isChosen = optionIndex == chosen
        let revealed = chosen != nil

        let fill: Color = {
            guard revealed else { return LexColor.surface }
            if isAnswer { return LexColor.mint }
            if isChosen { return LexColor.pastel(4).fill }
            return LexColor.surface
        }()
        let tone: Color = {
            guard revealed else { return LexColor.ink }
            if isAnswer { return LexColor.mintDeep }
            if isChosen { return LexColor.pastel(4).tone }
            return LexColor.slate
        }()

        return Button {
            selectOption(optionIndex, question: question)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(letters[min(optionIndex, letters.count - 1)])
                    .font(LexFont.sans(13, .bold))
                    .foregroundStyle(revealed && (isAnswer || isChosen) ? tone : LexColor.brand)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(revealed && (isAnswer || isChosen) ? Color.clear : LexColor.brandSoft))
                    .overlay(
                        Circle().strokeBorder(revealed && (isAnswer || isChosen) ? tone.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                Text(option)
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(tone)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                Spacer(minLength: 8)
                if revealed && isAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(LexColor.mintDeep)
                } else if revealed && isChosen {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(LexColor.pastel(4).tone)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(revealed && isAnswer ? LexColor.mintDeep.opacity(0.4) : LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .disabled(revealed)
        .animation(.easeOut(duration: 0.2), value: chosen)
    }

    private func selectOption(_ optionIndex: Int, question: QuizQuestion) {
        guard chosen == nil, !isFinished else { return }
        chosen = optionIndex
        if answers.indices.contains(index) {
            answers[index] = optionIndex
        }
        if optionIndex == question.answerIndex {
            correctTick += 1
        } else {
            wrongTick += 1
        }
        Task {
            try? await Task.sleep(for: .milliseconds(1000))
            advance()
        }
    }

    private func advance() {
        guard !isFinished else { return }
        if index + 1 < deck.count {
            index += 1
            chosen = nil
        } else {
            finish(timedOut: false)
        }
    }

    private func finish(timedOut expired: Bool) {
        guard !isFinished else { return }
        timedOut = expired
        remainingAtFinish = expired ? 0 : remaining
        let total = max(deck.count, 1)
        let correct = correctCount
        let percent = Int((Double(correct) / Double(total) * 100).rounded())
        let isPerfect = correct == deck.count && !deck.isEmpty

        store.recordQuizFinished(isPerfect: isPerfect)
        if store.isRewardStreakComplete,
           store.isWeeklyQuizRewardAvailable,
           let rule = QuizConfig.rule(for: deck.count),
           store.claimWeeklyQuizReward(credits: rule.credits, quizLabel: "\(deck.count) questions, \(percent)%") {
            claimedCredits = rule.credits
        }
        streakAtResult = store.quizPerfectStreak

        withAnimation(.spring(duration: 0.5)) {
            isFinished = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(duration: 1.0)) {
                ringProgress = Double(correct) / Double(total)
            }
        }
    }

    // MARK: Result

    private var resultView: some View {
        let total = max(deck.count, 1)
        let correct = correctCount
        let fraction = Double(correct) / Double(total)
        let percent = Int((fraction * 100).rounded())
        let isPerfect = correct == deck.count && !deck.isEmpty
        let unanswered = answers.filter { $0 == nil }.count
        let wrong = total - correct - unanswered

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(LexStrings.t("quiz.result.title", store.language))
                        .font(LexFont.display(24, .bold))
                        .foregroundStyle(LexColor.ink)
                    Spacer()
                    LexCloseButton { dismiss() }
                }
                .padding(.top, 14)

                ZStack {
                    Circle()
                        .stroke(LexColor.hairline, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            isPerfect ? LexColor.mintDeep : (fraction >= QuizConfig.passThreshold ? LexColor.brand : LexColor.saffron),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(percent)%")
                            .font(LexFont.display(38, .bold).monospacedDigit())
                            .foregroundStyle(LexColor.ink)
                            .contentTransition(.numericText())
                        Text("\(correct) / \(total)")
                            .font(LexFont.sans(14).monospacedDigit())
                            .foregroundStyle(LexColor.slate)
                    }
                }
                .frame(width: 156, height: 156)
                .frame(maxWidth: .infinity)
                .padding(.top, 22)

                Text(LexStrings.t(isPerfect ? "quiz.result.perfect" : (fraction >= QuizConfig.passThreshold ? "quiz.result.pass" : "quiz.result.fail"), store.language))
                    .font(LexFont.display(22, .bold))
                    .foregroundStyle(LexColor.ink)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                if timedOut {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "hourglass.bottomhalf.filled")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(LexColor.saffronDeep)
                        Text(LexStrings.t("quiz.result.timeUp", store.language))
                            .font(LexFont.sans(13))
                            .foregroundStyle(LexColor.ink)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LexColor.saffronSoft)
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.top, 14)
                }

                statsGrid(correct: correct, wrong: wrong, unanswered: unanswered, total: total)
                    .padding(.top, 18)

                if !timedOut && remainingAtFinish > 0 {
                    Text("\(LexStrings.t("quiz.time.left", store.language)): \(Self.timeString(remainingAtFinish))")
                        .font(LexFont.sans(12).monospacedDigit())
                        .foregroundStyle(LexColor.slate)
                        .padding(.top, 8)
                }

                streakPanel(isPerfect: isPerfect)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 2) {
                    LexOverline(text: LexStrings.t("quiz.review.title", store.language))
                    Text(LexStrings.t("quiz.review.sub", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 28)

                VStack(spacing: 10) {
                    ForEach(Array(deck.enumerated()), id: \.element.id) { questionIndex, question in
                        reviewCard(questionIndex, question)
                    }
                }
                .padding(.top, 12)

                VStack(spacing: 10) {
                    Button {
                        playAgain()
                    } label: {
                        Text(LexStrings.t("quiz.playAgain", store.language))
                            .font(LexFont.sans(16, .semibold))
                            .foregroundStyle(LexColor.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LexColor.brandSoft)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(LexPressStyle())
                    Button {
                        dismiss()
                    } label: {
                        Text(LexStrings.t("common.done", store.language))
                    }
                    .buttonStyle(LexPrimaryButtonStyle())
                }
                .padding(.top, 24)
                .padding(.bottom, 26)
            }
            .padding(.horizontal, 22)
        }
        .sensoryFeedback(.success, trigger: claimedCredits)
    }

    // MARK: Result blocks

    private func statsGrid(correct: Int, wrong: Int, unanswered: Int, total: Int) -> some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            statTile(
                value: "\(correct)",
                label: LexStrings.t("quiz.result.correct", store.language),
                fill: LexColor.mint,
                tone: LexColor.mintDeep
            )
            statTile(
                value: "\(wrong)",
                label: LexStrings.t("quiz.result.incorrect", store.language),
                fill: LexColor.pastel(4).fill,
                tone: LexColor.pastel(4).tone
            )
            if unanswered > 0 {
                statTile(
                    value: "\(unanswered)",
                    label: LexStrings.t("quiz.result.unanswered", store.language),
                    fill: LexColor.saffronSoft,
                    tone: LexColor.saffronDeep
                )
            } else {
                statTile(
                    value: "\(total)",
                    label: LexStrings.t("quiz.result.questions", store.language),
                    fill: LexColor.brandSoft,
                    tone: LexColor.brand
                )
            }
            statTile(
                value: Self.timeString(timeLimit - remainingAtFinish),
                label: LexStrings.t("quiz.time.used", store.language),
                fill: LexColor.blueSoft,
                tone: LexColor.blueDeep
            )
        }
    }

    private func statTile(value: String, label: String, fill: Color, tone: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(LexFont.display(20, .bold).monospacedDigit())
                .foregroundStyle(tone)
            Text(label)
                .font(LexFont.sans(11, .semibold))
                .foregroundStyle(tone.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(fill)
        .clipShape(.rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private func streakPanel(isPerfect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                LexOverline(text: LexStrings.t("quiz.streak.title", store.language), color: LexColor.saffronDeep)
                Spacer(minLength: 8)
                Text(LexStrings.f("quiz.streak.progress", store.language, streakAtResult, QuizConfig.streakTarget))
                    .font(LexFont.sans(12, .semibold).monospacedDigit())
                    .foregroundStyle(LexColor.ink)
            }
            QuizStreakMeter(streak: streakAtResult)
            if let claimedCredits {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LexColor.mintDeep)
                    Text("+\(claimedCredits) \(LexStrings.t("quiz.result.rewardAdded", store.language))")
                        .font(LexFont.sans(13, .semibold))
                        .foregroundStyle(LexColor.ink)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LexColor.mint)
                .clipShape(.rect(cornerRadius: 10))
                Text(LexStrings.t("quiz.streak.afterClaim", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
            } else {
                Text(streakMessage(isPerfect: isPerfect))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(claimedCredits != nil ? LexColor.mintDeep.opacity(0.35) : LexColor.hairline, lineWidth: 1)
        )
    }

    private func streakMessage(isPerfect: Bool) -> String {
        let language = store.language
        if streakAtResult >= QuizConfig.streakTarget {
            return LexStrings.t(store.isWeeklyQuizRewardAvailable ? "quiz.streak.ready" : "quiz.streak.complete", language)
        }
        if isPerfect {
            let left = QuizConfig.streakTarget - streakAtResult
            return left == 1
                ? LexStrings.t("quiz.streak.one", language)
                : LexStrings.f("quiz.streak.need", language, left)
        }
        return LexStrings.t("quiz.streak.reset", language)
    }

    // MARK: Review

    private func reviewCard(_ questionIndex: Int, _ question: QuizQuestion) -> some View {
        let userAnswer = answers.indices.contains(questionIndex) ? answers[questionIndex] : nil
        let isCorrect = userAnswer == question.answerIndex
        let statusTone = isCorrect ? LexColor.mintDeep : LexColor.pastel(4).tone
        let statusFill = isCorrect ? LexColor.mint : LexColor.pastel(4).fill

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Text("Q\(questionIndex + 1)")
                    .font(LexFont.sans(11, .bold).monospacedDigit())
                    .foregroundStyle(statusTone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(statusFill))
                Spacer(minLength: 8)
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(statusTone)
            }
            Text(question.prompt)
                .font(LexFont.sans(14, .medium))
                .foregroundStyle(LexColor.ink)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)

            if let userAnswer {
                answerLine(
                    label: LexStrings.t("quiz.review.your", store.language),
                    text: question.options[userAnswer],
                    tone: statusTone,
                    fill: statusFill
                )
            } else {
                answerLine(
                    label: LexStrings.t("quiz.review.notAnswered", store.language),
                    text: nil,
                    tone: LexColor.saffronDeep,
                    fill: LexColor.saffronSoft
                )
            }
            if !isCorrect {
                answerLine(
                    label: LexStrings.t("quiz.review.correct", store.language),
                    text: question.options[question.answerIndex],
                    tone: LexColor.mintDeep,
                    fill: LexColor.mint
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.hairline, lineWidth: 1)
        )
    }

    private func answerLine(label: String, text: String?, tone: Color, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(LexFont.sans(10, .bold))
                .foregroundStyle(tone)
                .textCase(.uppercase)
            if let text {
                Text(text)
                    .font(LexFont.sans(13, .medium))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill.opacity(0.55))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func playAgain() {
        deck = deck.shuffled()
        answers = Array(repeating: nil, count: deck.count)
        index = 0
        chosen = nil
        claimedCredits = nil
        ringProgress = 0
        timedOut = false
        remainingAtFinish = 0
        endDate = Date().addingTimeInterval(TimeInterval(timeLimit))
        remaining = timeLimit
        withAnimation(.easeOut(duration: 0.25)) {
            isFinished = false
        }
    }
}
