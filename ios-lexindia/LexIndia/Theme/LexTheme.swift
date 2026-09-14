//
//  LexTheme.swift
//  LexIndia
//
//  "Tringly" design system, adaptive to light and dark appearance.
//  Light: airy lilac-white canvas, clean white cards, deep bold plum ink.
//  Dark: deep purple canvas, plum cards, light near-white ink.
//  Vivid violet stays the action color in both; coral sparks stay warm.
//  Every token resolves for the current appearance, so views never need
//  to branch on the color scheme.
//

import SwiftUI
import UIKit

enum LexColor {
    // MARK: Adaptive machinery

    private nonisolated static func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    /// A color that resolves per the current appearance (light / dark).
    private nonisolated static func adaptive(
        _ lightHex: UInt32,
        _ darkHex: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        let light = rgb(lightHex, lightAlpha)
        let dark = rgb(darkHex, darkAlpha)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// White glass wash for chips sitting on pastel tiles — bright in
    /// light mode, a subtle lift in dark mode.
    nonisolated static func frost(_ lightAlpha: CGFloat, dark darkAlpha: CGFloat) -> Color {
        adaptive(0xFFFFFF, 0xFFFFFF, lightAlpha: lightAlpha, darkAlpha: darkAlpha)
    }

    // MARK: Core tokens (light / dark)

    /// The canvas — lilac near-white by day, deep purple by night.
    static let canvas = adaptive(0xFCFAFC, 0x120B21)
    /// Card surface — lilac off-white so cards clearly lift off the canvas / elevated plum.
    static let surface = adaptive(0xF1EDF7, 0x1E1B2E)
    /// Fine hairline for borders and dividers.
    static let hairline = adaptive(0x000000, 0xFFFFFF, lightAlpha: 0.10, darkAlpha: 0.10)
    /// Muted glyphs: chevrons and tertiary marks.
    static let faint = adaptive(0xA9A4B5, 0x8B85A0)
    /// Primary text — deep bold plum on light, near-white on dark.
    static let ink = adaptive(0x1E1B2E, 0xFCFAFC)
    /// Secondary text — muted plum-grey / light grey-lilac.
    static let slate = adaptive(0x5A5766, 0xB3ADC4)
    /// The action and highlight color — user-customisable in Settings.
    /// Derived per appearance by `ThemeStore`, which keeps contrast intact.
    static var brand: Color { ThemeStore.shared.brand }
    /// Pressed / deeper accent shade.
    static var brandDeep: Color { ThemeStore.shared.brandDeep }
    /// Accent-tinted panel surface.
    static var brandSoft: Color { ThemeStore.shared.brandSoft }
    /// Text and glyphs placed on accent fills.
    static var onBrand: Color { ThemeStore.shared.onBrand }
    /// Warm spark — diamonds, badges, ornaments. Follows the accent
    /// family when a custom app colour is chosen.
    static var saffron: Color { ThemeStore.shared.saffron }
    /// Accent text readable on the warm panel.
    static var saffronDeep: Color { ThemeStore.shared.saffronDeep }
    /// Warm panel.
    static var saffronSoft: Color { ThemeStore.shared.saffronSoft }
    /// Guide panel — the plain-language surface.
    static var blueSoft: Color { ThemeStore.shared.blueSoft }
    /// Text paired with blueSoft.
    static var blueDeep: Color { ThemeStore.shared.blueDeep }
    /// Success panel fill.
    static var mint: Color { ThemeStore.shared.mint }
    /// Text paired with mint.
    static var mintDeep: Color { ThemeStore.shared.mintDeep }
    /// The statute reads on paper — soft lilac sheet in both appearances.
    static let paper = adaptive(0xF0EAFB, 0x1B1530)
    /// Reading text on paper.
    static let onPaper = adaptive(0x2B2440, 0xEFE9FB)

    /// Pastel chip pairs (fill + readable tone) — friendly identities for
    /// laws, situations and tools. Colourful by default; shades of the
    /// accent when a custom app colour is active.
    static var pastelPairs: [(fill: Color, tone: Color)] {
        ThemeStore.shared.pastels.map { ($0.fill, $0.tone) }
    }

    /// Stable pastel pair for an index (cycles through the palette).
    static func pastel(_ index: Int) -> (fill: Color, tone: Color) {
        let pairs = ThemeStore.shared.pastels
        let pair = pairs[abs(index) % pairs.count]
        return (pair.fill, pair.tone)
    }
}

extension ThemeMode {
    /// The forced scheme, or nil to follow the iPhone's setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum LexFont {
    /// Friendly display sans — headings and numerals.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Interface sans — body and UI text.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Reserved serif — only for official statutory text, the voice of the statute.
    static func statute(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Scale-down press feedback used across tappable rows.
struct LexPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Primary call-to-action — vivid violet fill.
struct LexPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LexFont.sans(16, .semibold))
            .foregroundStyle(LexColor.onBrand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? LexColor.brandDeep : LexColor.brand)
            .clipShape(.rect(cornerRadius: 14))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
