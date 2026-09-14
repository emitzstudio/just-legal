//
//  ThemeStore.swift
//  LexIndia
//
//  The accent engine. The user picks ONE color (preset or wheel) and the
//  store derives a full supporting palette for both appearances.
//
//  Two modes:
//  · Signature (default LexIndia Violet) — the hand-tuned colourful mix:
//    violet actions, coral sparks, periwinkle guides, mint success and
//    eight pastel identities.
//  · Monochrome (any custom colour) — EVERY decorative token (tiles,
//    icons, badges, panels) re-derives as shades of the chosen hue, so
//    the whole app feels themed in that one colour family. Backgrounds
//    (canvas, surface, paper) never change — light stays light, dark
//    stays deep purple.
//

import SwiftUI
import UIKit
import Observation

@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private static let storageKey = "lexindia.accent.v1"

    /// A curated accent choice.
    nonisolated struct AccentPreset: Identifiable, Hashable {
        let id: String
        let name: String
        let hex: UInt32
    }

    /// One pastel identity pair (fill + readable tone).
    nonisolated struct PastelPair {
        let fill: Color
        let tone: Color
    }

    /// LexIndia Violet is the signature default; the rest are tuned to
    /// keep white text readable on the action color.
    static let presets: [AccentPreset] = [
        AccentPreset(id: "violet", name: "LexIndia Violet", hex: 0x9853F5),
        AccentPreset(id: "indigo", name: "Royal Indigo", hex: 0x4F46E5),
        AccentPreset(id: "peacock", name: "Peacock Teal", hex: 0x0D9488),
        AccentPreset(id: "forest", name: "Forest Green", hex: 0x15803D),
        AccentPreset(id: "marigold", name: "Marigold", hex: 0xD97706),
        AccentPreset(id: "rose", name: "Rose", hex: 0xE11D48),
        AccentPreset(id: "ocean", name: "Deep Ocean", hex: 0x0369A1),
        AccentPreset(id: "earth", name: "Earthen Brown", hex: 0x92400E)
    ]

    /// nil means the LexIndia Violet default (which has hand-tuned pairs).
    private(set) var accentHex: UInt32?

    // MARK: Derived palette — stored so @Observable change tracking fires.

    private(set) var brand: Color = ThemeStore.adaptive(0x9853F5, 0xA874FF)
    private(set) var brandDeep: Color = ThemeStore.adaptive(0x7C3AED, 0x9853F5)
    private(set) var brandSoft: Color = ThemeStore.adaptive(0xE9D5FE, 0x2C2145)
    private(set) var onBrand: Color = ThemeStore.adaptive(0xFFFFFF, 0x17102A)

    // Decorative tokens — colourful in signature mode, accent shades in
    // monochrome mode. Views reach these through LexColor.
    private(set) var saffron: Color = ThemeStore.adaptive(0xFF9B7B, 0xFF9B7B)
    private(set) var saffronDeep: Color = ThemeStore.adaptive(0xC2410C, 0xFFB399)
    private(set) var saffronSoft: Color = ThemeStore.adaptive(0xFFDFBC, 0x38221A)
    private(set) var blueSoft: Color = ThemeStore.adaptive(0xD3DCFE, 0x211E44)
    private(set) var blueDeep: Color = ThemeStore.adaptive(0x3730A3, 0xB4BEFF)
    private(set) var mint: Color = ThemeStore.adaptive(0xD2F0E0, 0x163227)
    private(set) var mintDeep: Color = ThemeStore.adaptive(0x166534, 0x8FE6B4)
    private(set) var pastels: [PastelPair] = ThemeStore.signaturePastels

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let value = UInt32(stored, radix: 16) {
            accentHex = value
        }
        recompute()
    }

    /// The currently selected accent as a plain color (light variant).
    var currentColor: Color {
        Color(uiColor: Self.rgb(accentHex ?? 0x9853F5))
    }

    var isDefault: Bool { accentHex == nil }

    /// Preset name, or "Custom" when picked from the wheel.
    var accentName: String {
        guard let accentHex else { return Self.presets[0].name }
        return Self.presets.first { $0.hex == accentHex }?.name ?? "Custom"
    }

    func isSelected(_ preset: AccentPreset) -> Bool {
        if let accentHex { return accentHex == preset.hex }
        return preset.hex == 0x9853F5
    }

    func selectPreset(_ preset: AccentPreset) {
        setAccent(hex: preset.hex == 0x9853F5 ? nil : preset.hex)
    }

    func setCustom(_ color: Color) {
        let ui = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
        let hex = (UInt32(round(red * 255)) << 16) | (UInt32(round(green * 255)) << 8) | UInt32(round(blue * 255))
        setAccent(hex: hex == 0x9853F5 ? nil : hex)
    }

    func reset() {
        setAccent(hex: nil)
    }

    private func setAccent(hex: UInt32?) {
        accentHex = hex
        recompute()
        if let hex {
            UserDefaults.standard.set(String(hex, radix: 16), forKey: Self.storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
    }

    // MARK: - Palette derivation

    private func recompute() {
        guard let hex = accentHex else {
            applySignature()
            return
        }
        applyMonochrome(hex)
    }

    /// The hand-tuned colourful LexIndia mix (default).
    private func applySignature() {
        brand = Self.adaptive(0x9853F5, 0xA874FF)
        brandDeep = Self.adaptive(0x7C3AED, 0x9853F5)
        brandSoft = Self.adaptive(0xE9D5FE, 0x2C2145)
        onBrand = Self.adaptive(0xFFFFFF, 0x17102A)
        saffron = Self.adaptive(0xFF9B7B, 0xFF9B7B)
        saffronDeep = Self.adaptive(0xC2410C, 0xFFB399)
        saffronSoft = Self.adaptive(0xFFDFBC, 0x38221A)
        blueSoft = Self.adaptive(0xD3DCFE, 0x211E44)
        blueDeep = Self.adaptive(0x3730A3, 0xB4BEFF)
        mint = Self.adaptive(0xD2F0E0, 0x163227)
        mintDeep = Self.adaptive(0x166534, 0x8FE6B4)
        pastels = Self.signaturePastels
    }

    /// Monochrome mode: every decorative token becomes a shade of the
    /// chosen hue. Roles keep their contrast relationships (pale panel +
    /// deep tone, dark panel + light tone) so readability never drops.
    private func applyMonochrome(_ hex: UInt32) {
        let base = Self.rgb(hex)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        // Action colour — deep enough for white text, alive enough to feel intentional.
        let famSat = sat < 0.12 ? sat : min(max(sat, 0.45), 1)
        let actionBri = min(max(bri, 0.34), 0.86)
        let light = Self.hsb(hue, famSat, actionBri)
        let dark = Self.hsb(hue, max(famSat * 0.82, sat < 0.12 ? 0 : 0.30), min(actionBri + 0.16, 1))

        brand = Self.dynamic(light: light, dark: dark)
        brandDeep = Self.dynamic(
            light: Self.hsb(hue, min(famSat * 1.05, 1), actionBri * 0.78),
            dark: Self.hsb(hue, famSat, min(actionBri + 0.04, 0.9))
        )
        brandSoft = Self.dynamic(
            light: Self.hsb(hue, min(max(famSat * 0.34, sat < 0.12 ? 0 : 0.10), 0.30), 0.97),
            dark: Self.hsb(hue, min(famSat * 0.55, 0.55), 0.25)
        )
        onBrand = Self.dynamic(
            light: Self.luminance(light) > 0.62 ? Self.rgb(0x1E1B2E) : .white,
            dark: Self.luminance(dark) > 0.62 ? Self.rgb(0x17102A) : .white
        )

        // Decorative shades — one hue family, distinct roles.
        func tone(_ satMul: CGFloat, _ brightness: CGFloat) -> UIColor {
            Self.hsb(hue, famSat * satMul, brightness)
        }

        // Spark (was coral): a bright lively shade of the accent.
        saffron = Self.dynamic(light: tone(0.62, min(actionBri + 0.26, 0.97)), dark: tone(0.52, 0.98))
        // Warm panel trio → three closely-related tints, still distinguishable.
        saffronDeep = Self.dynamic(light: tone(1.05, max(actionBri * 0.60, 0.30)), dark: tone(0.42, 0.95))
        saffronSoft = Self.dynamic(light: tone(0.32, 0.975), dark: tone(0.55, 0.27))
        blueSoft = Self.dynamic(light: tone(0.24, 0.965), dark: tone(0.48, 0.235))
        blueDeep = Self.dynamic(light: tone(1.1, max(actionBri * 0.52, 0.26)), dark: tone(0.38, 0.92))
        mint = Self.dynamic(light: tone(0.16, 0.955), dark: tone(0.42, 0.20))
        mintDeep = Self.dynamic(light: tone(0.95, max(actionBri * 0.46, 0.22)), dark: tone(0.32, 0.88))

        // Eight pastel identities — a stepped ladder of the same hue so
        // neighbouring tiles stay tellable-apart without leaving the family.
        pastels = (0..<8).map { index in
            let step = CGFloat(index) / 7
            let fillLight = Self.hsb(hue, famSat * (0.15 + 0.30 * step), 0.975 - 0.085 * step)
            let toneLight = Self.hsb(hue, min(famSat * (1.15 - 0.30 * step), 1), 0.30 + 0.13 * step)
            let fillDark = Self.hsb(hue, famSat * (0.34 + 0.24 * step), 0.16 + 0.13 * step)
            let toneDark = Self.hsb(hue, famSat * (0.46 - 0.14 * step), 0.97 - 0.09 * step)
            return PastelPair(
                fill: Self.dynamic(light: fillLight, dark: fillDark),
                tone: Self.dynamic(light: toneLight, dark: toneDark)
            )
        }
    }

    /// The signature pastel pairs (fill + readable tone) per appearance.
    private static let signaturePastels: [PastelPair] = [
        PastelPair(fill: adaptive(0xE6D0FE, 0x2B2052), tone: adaptive(0x4C1D95, 0xD9C7FF)),
        PastelPair(fill: adaptive(0xCCD6FE, 0x1F2350), tone: adaptive(0x3730A3, 0xB9C4FF)),
        PastelPair(fill: adaptive(0xC8ECD9, 0x143528), tone: adaptive(0x166534, 0x93E8BE)),
        PastelPair(fill: adaptive(0xFFDCB0, 0x3D2517), tone: adaptive(0x9A3412, 0xFFC9A6)),
        PastelPair(fill: adaptive(0xFFBDD0, 0x421B2A), tone: adaptive(0x9F1239, 0xFFAFC7)),
        PastelPair(fill: adaptive(0xF9C9E4, 0x3C1830), tone: adaptive(0x9D174D, 0xF5AEDC)),
        PastelPair(fill: adaptive(0xFBE45E, 0x38300E), tone: adaptive(0x854D0E, 0xF2E38E)),
        PastelPair(fill: adaptive(0xC3A6FF, 0x33265A), tone: adaptive(0x3B1544, 0xCFB8FF))
    ]

    // MARK: - Color math

    private nonisolated static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    private nonisolated static func hsb(_ hue: CGFloat, _ saturation: CGFloat, _ brightness: CGFloat) -> UIColor {
        UIColor(
            hue: hue,
            saturation: min(max(saturation, 0), 1),
            brightness: min(max(brightness, 0), 1),
            alpha: 1
        )
    }

    private nonisolated static func adaptive(_ lightHex: UInt32, _ darkHex: UInt32) -> Color {
        dynamic(light: rgb(lightHex), dark: rgb(darkHex))
    }

    private nonisolated static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Perceived luminance 0…1.
    private nonisolated static func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
}
