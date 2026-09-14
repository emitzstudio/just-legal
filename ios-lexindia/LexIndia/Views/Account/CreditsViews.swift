//
//  CreditsViews.swift
//  LexIndia
//
//  Credit balance, usage stats, buying more (with confirmation) and the
//  full credit history. This is the ONLY place the balance is shown.
//

import SwiftUI

struct CreditPack: Identifiable {
    let id: String
    let amount: Int
    let priceINR: Int
    let note: String?

    var priceLabel: String { "₹\(priceINR)" }
}

/// Mock packs — amounts and prices are finalized later, only here.
enum CreditPackCatalog {
    static let packs: [CreditPack] = [
        CreditPack(id: "p20", amount: 20, priceINR: 99, note: nil),
        CreditPack(id: "p60", amount: 60, priceINR: 249, note: "credits.pack.popular"),
        CreditPack(id: "p150", amount: 150, priceINR: 499, note: "credits.pack.best")
    ]
}

struct BuyCreditsSheet: View {
    @Environment(UserDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingPack: CreditPack?
    @State private var purchasedTrigger: Int = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LexStrings.t("account.credits.balance", store.language))
                            .font(LexFont.display(26, .bold))
                            .foregroundStyle(LexColor.ink)
                        Text(LexStrings.t("credits.explainer", store.language))
                            .font(LexFont.sans(14))
                            .foregroundStyle(LexColor.slate)
                            .lineSpacing(3)
                    }
                    Spacer()
                    LexCloseButton()
                }
                .padding(.top, 22)

                statsCard
                    .padding(.top, 18)

                if store.credits == 0 {
                    zeroPanel
                        .padding(.top, 14)
                } else if store.isLowOnCredits {
                    Text(LexStrings.t("credits.low", store.language))
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                        .padding(.top, 14)
                }

                LexOverline(text: LexStrings.t("credits.buyMore", store.language))
                    .padding(.top, 24)

                VStack(spacing: 10) {
                    ForEach(CreditPackCatalog.packs) { pack in
                        packRow(pack)
                    }
                }
                .padding(.top, 10)

                Text(LexStrings.t("credits.demo", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .padding(.top, 14)

                if !store.creditHistory.isEmpty {
                    LexOverline(text: LexStrings.t("credits.recent", store.language))
                        .padding(.top, 26)
                    VStack(spacing: 0) {
                        ForEach(Array(store.creditHistory.prefix(4).enumerated()), id: \.element.id) { index, transaction in
                            if index > 0 { LexHairline() }
                            CreditTransactionRow(transaction: transaction)
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.surface)
        .sensoryFeedback(.success, trigger: purchasedTrigger)
        .confirmationDialog(
            LexStrings.t("credits.demoTitle", store.language),
            isPresented: Binding(
                get: { confirmingPack != nil },
                set: { if !$0 { confirmingPack = nil } }
            ),
            titleVisibility: .visible,
            presenting: confirmingPack
        ) { pack in
            Button(LexStrings.f("credits.addPack", store.language, pack.amount, pack.priceLabel)) {
                purchase(pack)
            }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        } message: { pack in
            Text(LexStrings.f("credits.becomes", store.language, store.credits + pack.amount))
        }
    }

    // MARK: Stats

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(value: "\(store.credits)", label: LexStrings.t("credits.remaining", store.language), tone: LexColor.brand)
            statDivider
            stat(value: "\(store.creditsUsed)", label: LexStrings.t("credits.used", store.language), tone: LexColor.ink)
            statDivider
            stat(value: "\(store.creditsAdded)", label: LexStrings.t("credits.added", store.language), tone: LexColor.ink)
        }
        .padding(.vertical, 16)
        .background(LexColor.brandSoft)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(LexColor.brand.opacity(0.12))
            .frame(width: 1, height: 34)
    }

    private func stat(value: String, label: String, tone: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(LexFont.display(22, .bold).monospacedDigit())
                .foregroundStyle(tone)
                .contentTransition(.numericText())
            Text(label)
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
        }
        .frame(maxWidth: .infinity)
    }

    private var zeroPanel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.saffronDeep)
            Text(LexStrings.t("credits.out", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 14))
    }

    private func packRow(_ pack: CreditPack) -> some View {
        Button {
            confirmingPack = pack
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(pack.amount) \(LexStrings.t("quiz.reward.per", store.language))")
                        .font(LexFont.display(18, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .monospacedDigit()
                    if let note = pack.note {
                        LexOverline(text: LexStrings.t(note, store.language), color: LexColor.saffronDeep)
                    }
                }
                Spacer()
                Text(pack.priceLabel)
                    .font(LexFont.sans(17, .semibold))
                    .foregroundStyle(LexColor.brand)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(LexColor.canvas)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(pack.amount) credits for \(pack.priceLabel)")
    }

    private func purchase(_ pack: CreditPack) {
        store.addCredits(pack.amount, reason: "Purchased \(pack.amount) credits (\(pack.priceLabel))")
        purchasedTrigger += 1
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        }
    }
}

struct CreditTransactionRow: View {
    @Environment(UserDataStore.self) private var store

    let transaction: CreditTransaction

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.reason)
                    .font(LexFont.sans(14))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(1)
                Text(LexLocalize.dateTime(transaction.date, store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            Spacer()
            Text(transaction.delta > 0 ? "+\(transaction.delta)" : "\(transaction.delta)")
                .font(LexFont.sans(15, .semibold).monospacedDigit())
                .foregroundStyle(transaction.delta > 0 ? LexColor.mintDeep : LexColor.slate)
        }
        .padding(.vertical, 10)
    }
}

struct CreditHistoryView: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(LexStrings.t("account.credits.history", store.language))
                    .font(LexFont.display(28, .bold))
                    .foregroundStyle(LexColor.ink)
                    .padding(.top, 8)
                Text(LexStrings.f("credits.summary", store.language, store.credits, store.creditsUsed, store.creditsAdded))
                    .font(LexFont.sans(14))
                    .foregroundStyle(LexColor.slate)
                    .monospacedDigit()
                    .padding(.top, 3)

                if store.creditHistory.isEmpty {
                    LexEmptyState(
                        symbol: "clock.arrow.circlepath",
                        title: LexStrings.t("credits.emptyTitle", store.language),
                        message: LexStrings.t("credits.emptySub", store.language)
                    )
                    .padding(.top, 30)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.creditHistory.enumerated()), id: \.element.id) { index, transaction in
                            if index > 0 { LexHairline() }
                            CreditTransactionRow(transaction: transaction)
                        }
                    }
                    .padding(.top, 18)
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
