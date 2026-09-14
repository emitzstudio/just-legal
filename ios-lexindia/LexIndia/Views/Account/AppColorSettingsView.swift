//
//  AppColorSettingsView.swift
//  LexIndia
//
//  The app colour setting: curated presets plus a full colour wheel.
//  ThemeStore derives the complete supporting palette from the choice,
//  so contrast and hierarchy survive any colour.
//

import SwiftUI

struct AppColorSettingsView: View {
    @Environment(UserDataStore.self) private var store

    @State private var customColor: Color = ThemeStore.shared.currentColor

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("appcolor.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("appcolor.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                previewCard
                    .padding(.top, 18)

                familyRow
                    .padding(.top, 12)

                LexOverline(text: LexStrings.t("appcolor.presets", store.language))
                    .padding(.top, 26)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ThemeStore.presets) { preset in
                        presetSwatch(preset)
                    }
                }
                .padding(.top, 12)

                LexOverline(text: LexStrings.t("appcolor.custom", store.language))
                    .padding(.top, 26)

                customRow
                    .padding(.top, 10)

                if !ThemeStore.shared.isDefault {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            ThemeStore.shared.reset()
                            customColor = ThemeStore.shared.currentColor
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text(LexStrings.t("appcolor.reset", store.language))
                                .font(LexFont.sans(14, .semibold))
                        }
                        .foregroundStyle(LexColor.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(LexColor.brandSoft)
                        .clipShape(.rect(cornerRadius: 13))
                    }
                    .buttonStyle(LexPressStyle())
                    .padding(.top, 18)
                }

                VStack(alignment: .leading, spacing: 8) {
                    LexOverline(text: LexStrings.t("appcolor.preview", store.language), color: LexColor.blueDeep)
                    Text(LexStrings.t("appcolor.note", store.language))
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(LexColor.blueSoft)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Live preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                LexOverline(text: ThemeStore.shared.accentName, color: LexColor.onBrand.opacity(0.65))
                Spacer()
                AccentDiamond(size: 6, color: LexColor.onBrand)
            }
            Text("LexIndia")
                .font(LexFont.display(24, .bold))
                .foregroundStyle(LexColor.onBrand)
            HStack(spacing: 8) {
                Text("\(LexStrings.t("reader.section", store.language)) 318")
                    .font(LexFont.sans(12, .semibold))
                    .foregroundStyle(LexColor.onBrand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                Text(LexStrings.t("guide.badge", store.language))
                    .font(LexFont.sans(12, .semibold))
                    .foregroundStyle(LexColor.onBrand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                Spacer()
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LexColor.onBrand)
            }
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
        .clipShape(.rect(cornerRadius: 18))
        .animation(.easeOut(duration: 0.3), value: ThemeStore.shared.accentHex)
    }

    /// The derived decorative family — the shades tiles, icons and badges
    /// will use. Colourful in the default; monochrome for a custom colour.
    private var familyRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: LexStrings.t("appcolor.family", store.language))
            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(LexColor.pastel(index).fill)
                        .overlay(
                            Circle().strokeBorder(LexColor.pastel(index).tone.opacity(0.4), lineWidth: 1)
                        )
                        .frame(height: 26)
                        .frame(maxWidth: .infinity)
                }
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
        .animation(.easeOut(duration: 0.3), value: ThemeStore.shared.accentHex)
    }

    // MARK: Presets

    private func presetSwatch(_ preset: ThemeStore.AccentPreset) -> some View {
        let isSelected = ThemeStore.shared.isSelected(preset)
        return Button {
            withAnimation(.easeOut(duration: 0.25)) {
                ThemeStore.shared.selectPreset(preset)
                customColor = ThemeStore.shared.currentColor
            }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(Color(red: Double((preset.hex >> 16) & 0xFF) / 255,
                                    green: Double((preset.hex >> 8) & 0xFF) / 255,
                                    blue: Double(preset.hex & 0xFF) / 255))
                        .frame(width: 44, height: 44)
                    if isSelected {
                        Circle()
                            .strokeBorder(LexColor.ink, lineWidth: 2)
                            .frame(width: 54, height: 54)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 54, height: 54)
                Text(preset.name)
                    .font(LexFont.sans(10, .medium))
                    .foregroundStyle(isSelected ? LexColor.ink : LexColor.slate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("\(preset.name)\(isSelected ? ", selected" : "")")
    }

    // MARK: Custom wheel

    private var customRow: some View {
        HStack(spacing: 12) {
            ColorPicker(selection: $customColor, supportsOpacity: false) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LexStrings.t("appcolor.custom", store.language))
                        .font(LexFont.sans(15, .medium))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("appcolor.custom.pick", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
            }
            .onChange(of: customColor) { _, newValue in
                withAnimation(.easeOut(duration: 0.25)) {
                    ThemeStore.shared.setCustom(newValue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.hairline, lineWidth: 1)
        )
    }
}
