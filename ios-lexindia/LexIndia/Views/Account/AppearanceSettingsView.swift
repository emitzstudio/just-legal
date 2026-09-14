//
//  AppearanceSettingsView.swift
//  LexIndia
//
//  Theme mode selection: Automatic (follows the iPhone), Light or Dark.
//  Every color in the app is an adaptive token, so the whole interface
//  re-resolves instantly when the mode changes.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("appearance.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("appearance.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(ThemeMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        if index > 0 { LexHairline().padding(.leading, 16) }
                        modeRow(mode)
                    }
                }
                .background(LexColor.surface)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(LexColor.hairline, lineWidth: 1)
                )
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    LexOverline(text: LexStrings.t("appearance.how", store.language), color: LexColor.blueDeep)
                    Text(LexStrings.t("appearance.body1", store.language))
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(4)
                    Text(LexStrings.t("appearance.body2", store.language))
                        .font(LexFont.sans(13, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(LexColor.blueSoft)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modeRow(_ mode: ThemeMode) -> some View {
        let isSelected = store.themeMode == mode
        return Button {
            store.setThemeMode(mode)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? LexColor.onBrand : LexColor.slate)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(isSelected ? LexColor.brand : LexColor.canvas))
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.label(store.language))
                        .font(LexFont.sans(16, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(mode.detail(store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LexColor.brand)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(mode.label(store.language))\(isSelected ? ", selected" : "")")
    }
}
