//
//  EVakeelOverlay.swift
//  LexIndia
//
//  The E-Vakeel chat overlay — the assistant appears above the current
//  screen, keeps its own navigation for opening provisions, and returns
//  the user exactly where they were. Credits are charged per answer but
//  the balance is never shown here (only in Account).
//

import SwiftUI

struct EVakeelOverlay: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui

    @State private var input: String = ""
    @State private var isThinking: Bool = false
    @State private var needsMoreCredits: Bool = false
    @FocusState private var inputFocused: Bool

    private let provider = MockEVakeelProvider()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { close() }
                .accessibilityLabel("Close E-Vakeel")

            panel
                .padding(.top, 62)
        }
    }

    private func close() {
        inputFocused = false
        ui.evakeelPresented = false
    }

    // MARK: Panel

    private var panel: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                LexHairline()
                    .padding(.horizontal, 20)
                thread
                inputArea
            }
            .background(LexColor.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .lexDestinations()
        }
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 26, bottomLeading: 0, bottomTrailing: 0, topTrailing: 26)))
        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: -6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                EVakeelButtonFace(diameter: 40, showsSpark: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(LexStrings.t("evakeel.name", store.language))
                        .font(LexFont.display(19, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("evakeel.tagline", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer()
                if !store.evakeelRecords.isEmpty {
                    Menu {
                        Button(role: .destructive) {
                            store.clearEVakeel()
                        } label: {
                            Label(LexStrings.t("evakeel.clear", store.language), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LexColor.slate)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(LexColor.surface))
                            .overlay(Circle().strokeBorder(LexColor.hairline, lineWidth: 1))
                    }
                }
                LexCloseButton(action: close)
            }
            Text(LexStrings.t("evakeel.disclaimer", store.language))
                .font(LexFont.sans(11))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Thread

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if store.evakeelRecords.isEmpty && !isThinking {
                        emptyThread
                    }
                    ForEach(store.evakeelRecords) { record in
                        EVakeelRecordView(record: record)
                    }
                    if isThinking {
                        thinkingRow
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("evakeel-bottom")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: store.evakeelRecords.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("evakeel-bottom", anchor: .bottom)
                }
            }
            .onChange(of: isThinking) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("evakeel-bottom", anchor: .bottom)
                }
            }
        }
    }

    private var emptyThread: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(LexStrings.t("evakeel.empty.title", store.language))
                    .font(LexFont.display(22, .bold))
                    .foregroundStyle(LexColor.ink)
                Text(LexStrings.t("evakeel.empty.message", store.language))
                    .font(LexFont.sans(14))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.brandSoft)
            .clipShape(.rect(cornerRadius: 16))

            LexOverline(text: LexStrings.t("evakeel.try", store.language))
            VStack(spacing: 8) {
                ForEach(LexLocalize.suggestions(data.core.askSuggestions, store.language).prefix(4), id: \.self) { suggestion in
                    Button {
                        input = suggestion
                        send()
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(LexFont.sans(14, .medium))
                                .foregroundStyle(LexColor.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LexColor.brand)
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
                    .buttonStyle(LexPressStyle())
                }
            }
        }
    }

    private var thinkingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(LexColor.brand)
            Text(LexStrings.t("evakeel.thinking", store.language))
                .font(LexFont.sans(13))
                .italic()
                .foregroundStyle(LexColor.slate)
        }
        .padding(.vertical, 4)
    }

    // MARK: Input

    private var inputArea: some View {
        VStack(spacing: 10) {
            if store.credits == 0 {
                outOfCreditsPanel
            } else {
                if needsMoreCredits {
                    Text(LexStrings.t("evakeel.needMore", store.language))
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    TextField(LexStrings.t("evakeel.placeholder", store.language), text: $input, axis: .vertical)
                        .font(LexFont.sans(16))
                        .foregroundStyle(LexColor.ink)
                        .lineLimit(1...4)
                        .focused($inputFocused)
                        .disabled(isThinking)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 11)
                        .background(LexColor.surface)
                        .clipShape(.rect(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(inputFocused ? LexColor.brand : LexColor.hairline, lineWidth: 1)
                        )
                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? LexColor.brand : LexColor.faint)
                    }
                    .disabled(!canSend)
                    .buttonStyle(LexPressStyle())
                    .accessibilityLabel("Send question")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(LexColor.canvas)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking && store.credits > 0
    }

    private var outOfCreditsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LexStrings.t("evakeel.outOfCredits", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
            Button {
                close()
                ui.selectedTab = .account
            } label: {
                Text(LexStrings.t("evakeel.manage", store.language))
            }
            .buttonStyle(LexPrimaryButtonStyle())
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

    // MARK: Send

    private func send() {
        let question = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        let estimated = EVakeelPricing.estimatedCost(for: question)
        guard store.credits >= estimated else {
            needsMoreCredits = true
            return
        }
        needsMoreCredits = false
        input = ""
        store.appendEVakeel(EVakeelRecord(
            id: UUID(), role: "user", text: question,
            lead: nil, mappingNote: nil, sectionIds: [],
            cost: 0, advisory: nil, date: Date()
        ))
        isThinking = true
        Task {
            let reply = await provider.reply(to: question, data: data)
            if reply.matched {
                store.spendCredits(reply.cost, reason: "E-Vakeel — \(String(question.prefix(34)))")
            }
            store.appendEVakeel(EVakeelRecord(
                id: UUID(),
                role: "assistant",
                text: reply.text,
                lead: reply.lead,
                mappingNote: reply.mappingNote,
                sectionIds: reply.sectionIds,
                cost: reply.matched ? reply.cost : 0,
                advisory: reply.needsAdvocate ? LexStrings.t("evakeel.advocate", store.language) : nil,
                date: Date()
            ))
            isThinking = false
        }
    }
}

// MARK: - Thread entries

private struct EVakeelRecordView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    let record: EVakeelRecord

    var body: some View {
        if record.role == "user" {
            HStack {
                Spacer(minLength: 48)
                Text(record.text)
                    .font(LexFont.sans(15))
                    .foregroundStyle(LexColor.ink)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background(LexColor.brandSoft)
                    .clipShape(.rect(cornerRadius: 16))
            }
        } else {
            assistantBody
        }
    }

    private var assistantBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let mappingNote = record.mappingNote {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LexColor.saffronDeep)
                    Text(mappingNote)
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LexColor.blueSoft)
                .clipShape(.rect(cornerRadius: 10))
            }
            if let lead = record.lead {
                Text(lead)
                    .font(LexFont.sans(12))
                    .italic()
                    .foregroundStyle(LexColor.slate)
            }
            Text(record.text)
                .font(LexFont.sans(16))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(5)
                .lexTranslatable(record.text)
            ForEach(record.sectionIds, id: \.self) { sectionId in
                if let section = data.section(sectionId) {
                    provisionRow(section)
                }
            }
            if let advisory = record.advisory {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "person.bust")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                    Text(advisory)
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LexColor.saffronSoft)
                .clipShape(.rect(cornerRadius: 12))
            }
            costLine
        }
    }

    @ViewBuilder
    private var costLine: some View {
        if record.cost == 0 {
            Text(LexStrings.t("evakeel.noCharge", store.language))
                .font(LexFont.sans(11))
                .foregroundStyle(LexColor.saffronDeep)
        } else {
            Text("\(record.cost) \(LexStrings.t(record.cost == 1 ? "evakeel.creditUsed" : "evakeel.creditsUsed", store.language))")
                .font(LexFont.sans(11))
                .foregroundStyle(LexColor.faint)
        }
    }

    private func provisionRow(_ section: LegalSection) -> some View {
        NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
            VStack(alignment: .leading, spacing: 5) {
                LexOverline(text: LexStrings.t("evakeel.provision", store.language), color: LexColor.saffronDeep)
                Text("\(section.number) · \(section.title)")
                    .font(LexFont.display(17, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                Text(data.act(section.actId)?.name ?? "")
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                HStack(spacing: 4) {
                    Text(LexStrings.t("evakeel.openSection", store.language))
                        .font(LexFont.sans(14, .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(LexColor.brand)
                .padding(.top, 3)
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
        .buttonStyle(LexPressStyle())
    }
}
