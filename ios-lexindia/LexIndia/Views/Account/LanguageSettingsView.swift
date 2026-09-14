//
//  LanguageSettingsView.swift
//  LexIndia
//
//  Interface language selection. Built to grow: adding a case to
//  AppLanguage (plus its string table) adds it here automatically.
//  Official statutory text never changes with the interface language.
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("language.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("language.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                        if index > 0 { LexHairline().padding(.leading, 16) }
                        languageRow(language)
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
                    LexOverline(text: LexStrings.t("language.how", store.language), color: LexColor.saffronDeep)
                    Text(LexStrings.t("language.body1", store.language))
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(4)
                    Text(LexStrings.t("language.body2", store.language))
                        .font(LexFont.sans(13, .semibold))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(LexColor.saffronSoft)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.top, 20)

                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LexColor.slate)
                    Text(LexStrings.t("language.more", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        let isSelected = store.language == language
        return Button {
            store.setLanguage(language)
        } label: {
            HStack(spacing: 12) {
                Text(String(language.nativeName.prefix(1)))
                    .font(LexFont.display(16, .bold))
                    .foregroundStyle(isSelected ? LexColor.onBrand : LexColor.slate)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(isSelected ? LexColor.brand : LexColor.canvas))
                VStack(alignment: .leading, spacing: 1) {
                    Text(language.nativeName)
                        .font(LexFont.sans(16, .semibold))
                        .foregroundStyle(LexColor.ink)
                    if language.nativeName != language.englishName {
                        Text(language.englishName)
                            .font(LexFont.sans(12))
                            .foregroundStyle(LexColor.slate)
                    }
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
        .accessibilityLabel("\(language.englishName)\(isSelected ? ", selected" : "")")
    }
}
