//
//  PaywallView.swift
//  LexIndia
//
//  The subscription gate shown after sign-in when no access is active:
//  the five plans, the 24-hour free trial, and (development builds only)
//  permanent test access.
//

import SwiftUI

struct PaywallView: View {
    @Environment(AccessStore.self) private var access
    @Environment(UserDataStore.self) private var store

    @State private var selectedPlanId: String = PlanCatalog.plans.first?.id ?? "plan-12m"
    @State private var confirmingPlan: SubscriptionPlan?
    @State private var successTrigger: Int = 0
    @State private var confirmSignOut: Bool = false

    private var selectedPlan: SubscriptionPlan? {
        PlanCatalog.plan(selectedPlanId)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .padding(.top, 18)

                if access.accessExpired {
                    expiredNotice
                        .padding(.top, 16)
                }

                LexOverline(text: LexStrings.t("paywall.choose", store.language))
                    .padding(.top, 26)

                PlanSelectionList(selectedPlanId: $selectedPlanId)
                    .padding(.top, 12)

                if let plan = selectedPlan {
                    Button(LexStrings.f("paywall.continue", store.language, plan.priceLabel, LexLocalize.planDuration(months: plan.months, store.language))) {
                        confirmingPlan = plan
                    }
                    .buttonStyle(LexPrimaryButtonStyle())
                    .padding(.top, 18)
                }

                if !access.hasUsedTrial {
                    trialButton
                        .padding(.top, 12)
                }

                Text(LexStrings.t("paywall.demo", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 14)

                if DevConfig.permanentTestAccessEnabled {
                    devAccessPanel
                        .padding(.top, 28)
                }

                accountFooter
                    .padding(.top, 26)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: successTrigger)
        .confirmationDialog(
            "Demo checkout",
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
        .alert(LexStrings.t("account.signoutTitle", store.language), isPresented: $confirmSignOut) {
            Button(LexStrings.t("account.signout", store.language), role: .destructive) { access.signOut() }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                LexOverline(text: "LexIndia", color: LexColor.onBrand.opacity(0.62))
                Spacer()
                AccentDiamond(size: 7, color: LexColor.onBrand)
            }
            Text(LexStrings.t("paywall.hero", store.language))
                .font(LexFont.display(30, .bold))
                .foregroundStyle(LexColor.onBrand)
                .lineSpacing(2)
                .padding(.top, 10)
            VStack(alignment: .leading, spacing: 9) {
                heroFeature(LexStrings.t("paywall.feature1", store.language))
                heroFeature(LexStrings.t("paywall.feature2", store.language))
                heroFeature(LexStrings.t("paywall.feature3", store.language))
            }
            .padding(.top, 16)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [LexColor.brand, LexColor.brandDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 24))
    }

    private func heroFeature(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LexColor.onBrand)
            Text(text)
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.onBrand.opacity(0.92))
        }
    }

    private var expiredNotice: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "hourglass.bottomhalf.filled")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.saffronDeep)
            Text(LexStrings.t(access.expiredEntitlementWasTrial ? "paywall.expired.trial" : "paywall.expired.plan", store.language))
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.ink)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: Trial

    private var trialButton: some View {
        Button {
            startTrial()
        } label: {
            VStack(spacing: 3) {
                Text(LexStrings.t("paywall.try", store.language))
                    .font(LexFont.sans(16, .semibold))
                    .foregroundStyle(LexColor.brand)
                Text(LexStrings.t("paywall.try.sub", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.brand.opacity(0.45), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Try free for 24 hours. Full access, no payment.")
    }

    // MARK: DEVELOPMENT ONLY

    /// DEVELOPMENT ONLY — removed entirely when
    /// `DevConfig.permanentTestAccessEnabled` is false.
    private var devAccessPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LexColor.slate)
                LexOverline(text: LexStrings.t("account.devOnly", store.language))
            }
            Text(LexStrings.t("paywall.dev.note", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(3)
            Button {
                successTrigger += 1
                access.activateDevAccess()
            } label: {
                Text(LexStrings.t("paywall.dev.cta", store.language))
                    .font(LexFont.sans(14, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(LexColor.canvas)
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(LexColor.faint, lineWidth: 1)
                    )
            }
            .buttonStyle(LexPressStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.surface.opacity(0.6))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.faint.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }

    private var accountFooter: some View {
        VStack(spacing: 8) {
            if let user = access.user {
                HStack(spacing: 6) {
                    Text(LexStrings.f("paywall.signedIn", store.language, user.email))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                    Button(LexStrings.t("account.signout", store.language)) {
                        confirmSignOut = true
                    }
                    .font(LexFont.sans(12, .semibold))
                    .foregroundStyle(LexColor.brand)
                }
            }
            TrustFootnote()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private func subscribe(_ plan: SubscriptionPlan) {
        successTrigger += 1
        store.addCredits(plan.includedCredits, reason: "Included with the \(plan.durationLabel) plan")
        access.activateSubscription(plan)
    }

    private func startTrial() {
        successTrigger += 1
        access.startTrial()
    }
}

// MARK: - Plan list (shared with SubscriptionSheet)

struct PlanSelectionList: View {
    @Binding var selectedPlanId: String

    var body: some View {
        VStack(spacing: 10) {
            ForEach(PlanCatalog.plans) { plan in
                PlanRow(plan: plan, selected: plan.id == selectedPlanId) {
                    selectedPlanId = plan.id
                }
            }
        }
    }
}

private struct PlanRow: View {
    @Environment(UserDataStore.self) private var store

    let plan: SubscriptionPlan
    let selected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? LexColor.brand : LexColor.faint)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(LexLocalize.planDuration(months: plan.months, store.language))
                            .font(LexFont.display(17, .semibold))
                            .foregroundStyle(LexColor.ink)
                        if plan.isRecommended {
                            Text(LexStrings.t("paywall.best", store.language))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(LexColor.onBrand)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(LexColor.saffron))
                        }
                    }
                    Text(LexStrings.f("paywall.planLine", store.language, LexLocalize.perMonth(plan, store.language), plan.includedCredits))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(plan.priceLabel)
                        .font(LexFont.display(18, .bold).monospacedDigit())
                        .foregroundStyle(LexColor.brand)
                    if let savings = plan.savingsINR {
                        Text(LexStrings.f("paywall.save", store.language, savings))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LexColor.mintDeep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(LexColor.mint))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(selected ? LexColor.brandSoft : LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        selected ? LexColor.brand : (plan.isRecommended ? LexColor.saffron : LexColor.hairline),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .animation(.easeOut(duration: 0.15), value: selected)
        .accessibilityLabel("\(plan.durationLabel), \(plan.priceLabel), includes \(plan.includedCredits) E-Vakeel credits\(plan.isRecommended ? ", best value" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
