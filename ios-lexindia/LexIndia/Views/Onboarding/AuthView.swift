//
//  AuthView.swift
//  LexIndia
//
//  First-run gate: create an account or sign in. Preview authentication —
//  accounts live on this device until the production backend arrives.
//

import SwiftUI

enum AuthMode: String, CaseIterable, Identifiable {
    case register = "Create account"
    case signIn = "Sign in"

    var id: String { rawValue }
}

struct AuthView: View {
    @Environment(AccessStore.self) private var access
    @Environment(UserDataStore.self) private var store

    @State private var mode: AuthMode = .register
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var successTrigger: Int = 0
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case email
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .padding(.top, 28)

                modePicker
                    .padding(.top, 28)

                formCard
                    .padding(.top, 14)

                if let errorMessage {
                    Text(errorMessage)
                        .font(LexFont.sans(13, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                Button(LexStrings.t(mode == .register ? "auth.register" : "auth.signin", store.language)) {
                    submit()
                }
                .buttonStyle(LexPrimaryButtonStyle())
                .padding(.top, 18)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = mode == .register ? .signIn : .register
                        errorMessage = nil
                    }
                } label: {
                    Text(.init(LexStrings.t(mode == .register ? "auth.toggle.toSignin" : "auth.toggle.toRegister", store.language)))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                        .tint(LexColor.brand)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)

                VStack(spacing: 6) {
                    Text(LexStrings.t("auth.preview.note", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                    TrustFootnote()
                }
                .padding(.top, 34)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LexColor.canvas.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: successTrigger)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("§")
                    .font(LexFont.statute(30, .bold))
                    .foregroundStyle(LexColor.brand)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(LexColor.onBrand))
                Spacer()
                AccentDiamond(size: 8, color: LexColor.onBrand)
            }
            Text("LexIndia")
                .font(LexFont.display(34, .bold))
                .foregroundStyle(LexColor.onBrand)
                .padding(.top, 16)
            Text(LexStrings.t("auth.tagline", store.language))
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.onBrand.opacity(0.82))
                .lineSpacing(4)
                .padding(.top, 6)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LexColor.brand)
        .clipShape(.rect(cornerRadius: 24))
    }

    // MARK: Mode & form

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(AuthMode.allCases) { mode in
                Text(LexStrings.t(mode == .register ? "auth.register" : "auth.signin", store.language)).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in
            errorMessage = nil
        }
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            if mode == .register {
                field(
                    symbol: "person",
                    placeholder: LexStrings.t("account.yourName", store.language),
                    text: $name,
                    contentType: .name,
                    keyboard: .default,
                    focus: .name
                )
                LexHairline().padding(.leading, 46)
            }
            field(
                symbol: "envelope",
                placeholder: LexStrings.t("auth.email", store.language),
                text: $email,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                focus: .email
            )
        }
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.hairline, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: mode)
    }

    private func field(
        symbol: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        focus: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(focusedField == focus ? LexColor.brand : LexColor.slate)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .font(LexFont.sans(16))
                .foregroundStyle(LexColor.ink)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(contentType == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: focus)
                .submitLabel(focus == .name ? .next : .done)
                .onSubmit {
                    if focus == .name {
                        focusedField = .email
                    } else {
                        submit()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    // MARK: Submit

    private func submit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard isValidEmail(trimmedEmail) else {
            errorMessage = LexStrings.t("auth.err.email", store.language)
            return
        }

        switch mode {
        case .register:
            guard !trimmedName.isEmpty else {
                errorMessage = LexStrings.t("auth.err.name", store.language)
                focusedField = .name
                return
            }
            errorMessage = nil
            successTrigger += 1
            store.setName(trimmedName)
            access.register(name: trimmedName, email: trimmedEmail)
        case .signIn:
            if access.signIn(email: trimmedEmail) {
                errorMessage = nil
                successTrigger += 1
            } else {
                errorMessage = LexStrings.t("auth.err.notFound", store.language)
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.contains(".") && value.count >= 6 && !value.contains(" ")
    }
}
