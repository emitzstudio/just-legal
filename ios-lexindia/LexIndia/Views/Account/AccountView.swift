//
//  AccountView.swift
//  LexIndia
//
//  Profile, membership, credits, saved content, settings and sign out —
//  clear hierarchy, not a dashboard.
//

import SwiftUI

struct AccountView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(AccessStore.self) private var access

    @State private var showSubscription: Bool = false
    @State private var showBuyCredits: Bool = false
    @State private var showRename: Bool = false
    @State private var confirmSignOut: Bool = false
    @State private var nameDraft: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(LexStrings.t("account.title", store.language))
                        .font(LexFont.display(34, .bold))
                        .foregroundStyle(LexColor.ink)
                    Spacer()
                    LexSearchButton()
                }
                .padding(.top, 14)

                profileRow
                    .padding(.top, 18)

                membershipCard
                    .padding(.top, 22)

                group(LexStrings.t("account.credits", store.language)) {
                    actionRow(title: LexStrings.t("account.credits.balance", store.language), value: "\(store.credits) \(LexStrings.t("account.credits.left", store.language))", symbol: "diamond") {
                        showBuyCredits = true
                    }
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.credits.history", store.language), symbol: "clock.arrow.circlepath", destination: .creditHistory)
                }

                Text(LexStrings.t("account.credits.note", store.language))
                    .font(LexFont.sans(11))
                    .foregroundStyle(LexColor.slate)
                    .padding(.top, 6)
                    .padding(.leading, 4)

                group(LexStrings.t("account.yourLibrary", store.language)) {
                    navRow(title: LexStrings.t("account.saved", store.language), value: store.saved.isEmpty ? nil : "\(store.saved.count)", symbol: "bookmark", destination: .notes)
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.recents", store.language), symbol: "clock", destination: .recents)
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.downloads", store.language), value: store.downloads.isEmpty ? nil : "\(store.downloads.count)", symbol: "arrow.down.circle", destination: .downloads)
                }

                group(LexStrings.t("account.studyTools", store.language)) {
                    navRow(title: LexStrings.t("account.definitions", store.language), symbol: "character.book.closed", destination: .definitions)
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.caseLaws", store.language), symbol: "text.quote", destination: .caseLaws)
                    LexHairline().padding(.leading, 16)
                    navRow(title: "IPC → BNS", symbol: "arrow.left.arrow.right", destination: .ipcBns)
                }

                group(LexStrings.t("account.settings", store.language)) {
                    navRow(title: LexStrings.t("account.appearance", store.language), value: store.themeMode.label(store.language), symbol: "circle.lefthalf.filled", destination: .appearance)
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.appColor", store.language), value: ThemeStore.shared.accentName, symbol: "paintpalette", destination: .appColor)
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.language", store.language), value: store.language.nativeName, symbol: "globe", destination: .language)
                }

                group(LexStrings.t("account.about", store.language)) {
                    navRow(title: LexStrings.t("account.privacy", store.language), symbol: "lock", destination: .legalPage(.privacy))
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.terms", store.language), symbol: "doc.plaintext", destination: .legalPage(.terms))
                    LexHairline().padding(.leading, 16)
                    navRow(title: LexStrings.t("account.disclaimer", store.language), symbol: "info.circle", destination: .legalPage(.disclaimer))
                }

                group(LexStrings.t("account.session", store.language)) {
                    actionRow(title: LexStrings.t("account.signout", store.language), symbol: "rectangle.portrait.and.arrow.right") {
                        confirmSignOut = true
                    }
                }

                VStack(spacing: 6) {
                    TrustFootnote()
                    Text("LexIndia 1.0")
                        .font(LexFont.sans(11))
                        .foregroundStyle(LexColor.slate)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSubscription) {
            SubscriptionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(LexColor.surface)
        }
        .sheet(isPresented: $showBuyCredits) {
            BuyCreditsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(LexColor.surface)
        }
        .alert(LexStrings.t("account.yourName", store.language), isPresented: $showRename) {
            TextField(LexStrings.t("common.name", store.language), text: $nameDraft)
            Button(LexStrings.t("common.save", store.language)) {
                store.setName(nameDraft)
            }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        } message: {
            Text(LexStrings.t("account.name.note", store.language))
        }
        .alert(LexStrings.t("account.signoutTitle", store.language), isPresented: $confirmSignOut) {
            Button(LexStrings.t("account.signout", store.language), role: .destructive) {
                access.signOut()
            }
            Button(LexStrings.t("common.cancel", store.language), role: .cancel) {}
        } message: {
            Text(LexStrings.t("account.local.note", store.language))
        }
    }

    private var profileRow: some View {
        Button {
            nameDraft = store.profileName
            showRename = true
        } label: {
            HStack(spacing: 14) {
                Text(String(store.profileName.prefix(1)).uppercased())
                    .font(LexFont.display(22, .bold))
                    .foregroundStyle(LexColor.onBrand)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(LexColor.brand))
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.profileName)
                        .font(LexFont.display(19, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(access.user?.email ?? "Tap to edit your name")
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LexColor.slate)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Edit name, currently \(store.profileName)")
    }

    // MARK: Membership

    private var membershipCard: some View {
        Button {
            showSubscription = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    LexOverline(text: LexStrings.t("account.membership", store.language), color: LexColor.onBrand.opacity(0.62))
                    Spacer()
                    membershipBadge
                }
                membershipBody
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
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }

    @ViewBuilder
    private var membershipBadge: some View {
        if access.isDevAccess {
            badge("DEVELOPMENT")
        } else if access.subscriptionInfo != nil {
            badge("ACTIVE")
        } else if access.isOnTrial {
            badge("TRIAL")
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(LexColor.saffron)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(LexColor.onBrand))
    }

    @ViewBuilder
    private var membershipBody: some View {
        if let info = access.subscriptionInfo {
            Text("\(LexLocalize.planDuration(months: info.plan.months, store.language)) \(LexStrings.t("plan.suffix", store.language))")
                .font(LexFont.display(21, .semibold))
                .foregroundStyle(LexColor.onBrand)
            Text(LexStrings.f("account.expiresLine", store.language, LexLocalize.date(info.end, store.language), info.plan.includedCredits))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.onBrand.opacity(0.78))
                .lineSpacing(3)
            manageLine(LexStrings.t("account.managePlan", store.language))
        } else if access.isOnTrial {
            Text(LexStrings.t("myspace.trial", store.language))
                .font(LexFont.display(21, .semibold))
                .foregroundStyle(LexColor.onBrand)
            if let remaining = access.trialRemaining {
                Text(LexStrings.f("account.trial.line", store.language, LexLocalize.remaining(remaining, store.language)))
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.onBrand.opacity(0.78))
            }
            manageLine(LexStrings.t("myspace.seePlans", store.language))
        } else if access.isDevAccess {
            Text(LexStrings.t("account.testAccess", store.language))
                .font(LexFont.display(21, .semibold))
                .foregroundStyle(LexColor.onBrand)
            Text(LexStrings.t("account.dev.note", store.language))
                .font(LexFont.sans(13))
                .foregroundStyle(LexColor.onBrand.opacity(0.78))
                .lineSpacing(3)
            manageLine(LexStrings.t("myspace.seePlans", store.language))
        } else {
            Text(LexStrings.t("account.plus.note", store.language))
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.onBrand.opacity(0.9))
                .lineSpacing(4)
            manageLine(LexStrings.t("myspace.seePlans", store.language))
        }
    }

    private func manageLine(_ label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(LexFont.sans(14, .semibold))
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(LexColor.onBrand)
        .padding(.top, 2)
    }

    // MARK: Rows

    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: title)
            VStack(spacing: 0) {
                content()
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
        .padding(.top, 22)
    }

    private func navRow(title: String, value: String? = nil, symbol: String, destination: Destination) -> some View {
        NavigationLink(value: destination) {
            rowContent(title: title, value: value, symbol: symbol)
        }
        .buttonStyle(LexPressStyle())
    }

    private func actionRow(title: String, value: String? = nil, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(title: title, value: value, symbol: symbol)
        }
        .buttonStyle(LexPressStyle())
    }

    private func rowContent(title: String, value: String?, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 24)
            Text(title)
                .font(LexFont.sans(15, .medium))
                .foregroundStyle(LexColor.ink)
            Spacer()
            if let value {
                Text(value)
                    .font(LexFont.sans(14).monospacedDigit())
                    .foregroundStyle(LexColor.slate)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}
