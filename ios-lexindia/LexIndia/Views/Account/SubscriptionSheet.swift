//
//  SubscriptionSheet.swift
//  LexIndia
//
//  Membership management inside the app: the five plans, the current
//  entitlement (subscription, trial or dev test access) and cancellation.
//

import SwiftUI

struct SubscriptionSheet: View {
    @Environment(AccessStore.self) private var access
    @Environment(UserDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlanId: String = PlanCatalog.plans.first?.id ?? "plan-12m"
    @State private var confirmingPlan: SubscriptionPlan?
    @State private var confirmCancel: Bool = false
    @State private var confirmEndDevAccess: Bool = false
    @State private var successTrigger: Int = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero

                if let info = access.subscriptionInfo {
                    activeBlock(info)
                } else {
                    if access.isOnTrial {
                        trialStatusPanel
                            .padding(.top, 18)
                    }
                    if access.isDevAccess {
                        devStatusPanel
                            .padding(.top, 18)
                    }

                    LexOverline(text: LexStrings.t("sub.plans", store.language))
                        .padding(.top, 24)
                    PlanSelectionList(selectedPlanId: $selectedPlanId)
                        .padding(.top, 12)

                    if let plan = PlanCatalog.plan(selectedPlanId) {
                        Button(LexStrings.f("paywall.continue", store.language, plan.priceLabel, LexLocalize.planDuration(months: plan.months, store.language))) {
                            confirmingPlan = plan
                        }
                        .buttonStyle(LexPrimaryButtonStyle())
                        .padding(.top, 18)
                    }

                    featureList
                        .padding(.top, 26)

                    Text(LexStrings.t("paywall.demo", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                }

                Spacer().frame(height: 34)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.surface)
        .sensoryFeedback(.success, trigger: successTrigger)
        .confirmationDialog(
            LexStrings.t("paywall.demoTitle", store.language),
            isPresented: Binding(
                get: { confirmingPlan != nil },
                set: { if !$0 { confirmingPlan = nil } }
            ),
            titleVisibility: .visible,
            presenting: confirmingPlan
        ) { plan in
            Button(LexStrings.f("paywall.start", store.language, LexLocalize.planDuration(months: plan.months, store.language), plan.priceLabel)) {
                subscribe(plan)
            }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        } message: { plan in
            Text(LexStrings.f("paywall.includes", store.language, plan.includedCredits))
        }
        .alert(LexStrings.t("sub.cancelTitle", store.language), isPresented: $confirmCancel) {
            Button(LexStrings.t("sub.cancel", store.language), role: .destructive) {
                access.cancelSubscription()
                dismiss()
            }
            Button(LexStrings.t("sub.keepPlan", store.language), role: .cancel) {}
        } message: {
            Text(LexStrings.t("sub.cancelMessage", store.language))
        }
        .alert(LexStrings.t("sub.dev.endTitle", store.language), isPresented: $confirmEndDevAccess) {
            Button(LexStrings.t("sub.dev.end", store.language), role: .destructive) {
                access.endDevAccess()
                dismiss()
            }
            Button(LexStrings.t("sub.dev.keep", store.language), role: .cancel) {}
        } message: {
            Text(LexStrings.t("sub.dev.endMessage", store.language))
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            LexOverline(text: LexStrings.t("sub.membership", store.language), color: LexColor.onBrand.opacity(0.62))
            Text(LexStrings.t("sub.title", store.language))
                .font(LexFont.display(30, .bold))
                .foregroundStyle(LexColor.onBrand)
            Text(LexStrings.t("sub.tagline", store.language))
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.onBrand.opacity(0.82))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [LexColor.brand, LexColor.brandDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 18))
        .padding(.top, 22)
    }

    // MARK: Current entitlement states

    private var trialStatusPanel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "hourglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.saffronDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text(LexStrings.t("sub.trial.active", store.language))
                    .font(LexFont.sans(15, .semibold))
                    .foregroundStyle(LexColor.ink)
                if let remaining = access.trialRemaining {
                    Text(LexStrings.f("sub.trial.endsLine", store.language, LexLocalize.remaining(remaining, store.language)))
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 14))
    }

    /// DEVELOPMENT ONLY status — hidden in production builds.
    private var devStatusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LexColor.slate)
                LexOverline(text: LexStrings.t("account.devOnly", store.language))
                Spacer()
                Button(LexStrings.t("sub.dev.end", store.language)) {
                    confirmEndDevAccess = true
                }
                .font(LexFont.sans(13, .semibold))
                .foregroundStyle(LexColor.brand)
            }
            Text(LexStrings.t("sub.dev.active", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.canvas)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.faint.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }

    private func activeBlock(_ info: (plan: SubscriptionPlan, start: Date, end: Date)) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(LexColor.mintDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LexStrings.f("sub.planActive", store.language, LexLocalize.planDuration(months: info.plan.months, store.language)))
                        .font(LexFont.display(18, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.f("sub.planLine", store.language, info.plan.priceLabel, info.plan.includedCredits))
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                }
            }

            VStack(spacing: 0) {
                detailRow(LexStrings.t("sub.started", store.language), LexLocalize.date(info.start, store.language))
                LexHairline()
                detailRow(LexStrings.t("sub.expires", store.language), LexLocalize.date(info.end, store.language))
                LexHairline()
                detailRow(LexStrings.t("sub.balance", store.language), "\(store.credits)")
            }
            .background(LexColor.canvas)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )

            featureList

            Button(LexStrings.t("sub.cancel", store.language), role: .destructive) {
                confirmCancel = true
            }
            .font(LexFont.sans(14, .medium))
            .padding(.top, 4)
        }
        .padding(.top, 22)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.slate)
            Spacer()
            Text(value)
                .font(LexFont.sans(14, .semibold).monospacedDigit())
                .foregroundStyle(LexColor.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            LexOverline(text: LexStrings.t("sub.included", store.language))
            feature(LexStrings.t("sub.feat1", store.language))
            feature(LexStrings.t("sub.feat2", store.language))
            feature(LexStrings.t("sub.feat3", store.language))
            feature(LexStrings.t("sub.feat4", store.language))
            feature(LexStrings.t("sub.feat5", store.language))
        }
    }

    private func feature(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.mintDeep)
            Text(text)
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
        }
    }

    // MARK: Actions

    private func subscribe(_ plan: SubscriptionPlan) {
        successTrigger += 1
        store.addCredits(plan.includedCredits, reason: "Included with the \(plan.durationLabel) plan")
        access.activateSubscription(plan)
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        }
    }
}
